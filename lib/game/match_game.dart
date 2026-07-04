import 'dart:async';
import 'dart:math';
import 'dart:ui' show Gradient, PlatformDispatcher;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' hide Gradient;
import 'package:flutter/services.dart' show HapticFeedback;

import 'board.dart';
import 'candy_component.dart';
import 'candy_sprites.dart';
import 'candy_spec.dart';
import 'effects.dart';
import 'levels.dart';
import 'sfx.dart';

enum GameStatus { playing, won, lost }

/// 游戏主类：输入、结算循环、特效调度。
class MatchGame extends FlameGame with DragCallbacks, TapCallbacks {
  MatchGame({required this.level, required this.onStateChanged});

  static const int rows = 8;
  static const int cols = 8;

  final LevelConfig level;
  final void Function() onStateChanged;

  late Board board;
  late double cellSize;
  late Vector2 boardOrigin;

  final Map<Pos, CandyComponent> candyMap = {};

  int score = 0;
  late int movesLeft = level.moves;
  GameStatus status = GameStatus.playing;
  bool _busy = false; // 结算中禁止输入

  // 道具
  BoosterType? armedBooster;
  Map<BoosterType, int> boosterCounts = {
    BoosterType.hammer: 3,
    BoosterType.bomb: 2,
    BoosterType.shuffle: 2,
  };

  // 拖拽状态
  Pos? _dragStart;
  Vector2? _dragStartWorld;

  // 屏幕震动
  double _shakeTime = 0;
  double _shakeAmp = 0;
  final _rng = Random();
  late final World _world;
  late final CameraComponent _camera;

  bool get busy => _busy;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    _world = World();
    _camera = CameraComponent(world: _world)
      ..viewfinder.anchor = Anchor.topLeft;
    addAll([_world, _camera]);

    board = Board(rows, cols, colorCount: level.colorCount);
    _layout();
    // 按设备像素比预渲染糖果纹理，连击时不再矢量重绘
    CandySprites.dpr =
        PlatformDispatcher.instance.views.first.devicePixelRatio;
    CandySprites.warmUp(cellSize);
    _world.add(_BoardBackground(
      origin: boardOrigin,
      cellSize: cellSize,
      rows: rows,
      cols: cols,
    ));
    _spawnAll();
  }

  void _layout() {
    final w = size.x;
    final h = size.y;
    cellSize = min(w * 0.97 / cols, h * 0.9 / rows);
    boardOrigin = Vector2(
      (w - cellSize * cols) / 2,
      // 略偏上（45%），视觉重心更稳
      max(8, (h - cellSize * rows) * 0.45),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;
    _layout();
  }

  Vector2 cellCenter(Pos p) => Vector2(
        boardOrigin.x + (p.col + 0.5) * cellSize,
        boardOrigin.y + (p.row + 0.5) * cellSize,
      );

  Pos? worldToGrid(Vector2 world) {
    final c = ((world.x - boardOrigin.x) / cellSize).floor();
    final r = ((world.y - boardOrigin.y) / cellSize).floor();
    final p = Pos(r, c);
    return board.inBounds(p) ? p : null;
  }

  void _spawnAll() {
    for (final comp in candyMap.values) {
      comp.removeFromParent();
    }
    candyMap.clear();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final pos = Pos(r, c);
        final cell = board.at(pos)!;
        final comp = CandyComponent(
          cell: cell,
          gridPos: pos,
          cellSize: cellSize,
        )..position = cellCenter(pos);
        candyMap[pos] = comp;
        _world.add(comp);
      }
    }
  }

  // ---------- 屏幕震动 ----------

  void shakeScreen({double amplitude = 6, double duration = 0.25}) {
    _shakeAmp = max(_shakeAmp, amplitude);
    _shakeTime = max(_shakeTime, duration);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTime > 0) {
      _shakeTime -= dt;
      final f = (_shakeTime / 0.25).clamp(0.0, 1.0);
      _camera.viewfinder.position = Vector2(
        (_rng.nextDouble() - 0.5) * 2 * _shakeAmp * f,
        (_rng.nextDouble() - 0.5) * 2 * _shakeAmp * f,
      );
      if (_shakeTime <= 0) {
        _camera.viewfinder.position = Vector2.zero();
        _shakeAmp = 0;
      }
    }
  }

  // ---------- 输入 ----------

  @override
  void onTapDown(TapDownEvent event) {
    if (_busy || status != GameStatus.playing) return;
    final p = worldToGrid(event.localPosition);
    if (p == null) return;

    // 道具模式
    if (armedBooster != null && armedBooster != BoosterType.shuffle) {
      _useBoosterAt(armedBooster!, p);
      return;
    }

    final current = _selected;
    if (current == null) {
      _select(p);
    } else if (current == p) {
      _select(null);
    } else if (board.areAdjacent(current, p)) {
      _select(null);
      _trySwap(current, p);
    } else {
      _select(p);
    }
  }

  Pos? _selected;

  void _select(Pos? p) {
    if (_selected != null) {
      candyMap[_selected]?.selected = false;
    }
    _selected = p;
    if (p != null) {
      candyMap[p]?.selected = true;
      HapticFeedback.selectionClick();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_busy || status != GameStatus.playing || armedBooster != null) return;
    _dragStart = worldToGrid(event.localPosition);
    _dragStartWorld = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragStart == null || _dragStartWorld == null || _busy) return;
    final delta = event.localEndPosition - _dragStartWorld!;
    if (delta.length < cellSize * 0.35) return;
    Pos target;
    if (delta.x.abs() > delta.y.abs()) {
      target = Pos(_dragStart!.row, _dragStart!.col + (delta.x > 0 ? 1 : -1));
    } else {
      target = Pos(_dragStart!.row + (delta.y > 0 ? 1 : -1), _dragStart!.col);
    }
    final from = _dragStart!;
    _dragStart = null;
    _dragStartWorld = null;
    if (board.inBounds(target)) {
      _select(null);
      _trySwap(from, target);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragStart = null;
    _dragStartWorld = null;
  }

  // ---------- 交换与结算 ----------

  Future<void> _trySwap(Pos a, Pos b) async {
    if (_busy) return;
    _busy = true;
    final ca = candyMap[a]!;
    final cb = candyMap[b]!;

    if (!board.isValidSwap(a, b)) {
      // 无效交换：来回摆动
      Sfx.invalid();
      HapticFeedback.vibrate();
      await Future.wait([
        ca.moveToGrid(b, speed: 10),
        cb.moveToGrid(a, speed: 10),
      ]);
      await Future.wait([
        ca.moveToGrid(a, speed: 10),
        cb.moveToGrid(b, speed: 10),
      ]);
      await ca.shake();
      _busy = false;
      return;
    }

    Sfx.swap();
    HapticFeedback.lightImpact();
    await Future.wait([
      ca.moveToGrid(b, speed: 10),
      cb.moveToGrid(a, speed: 10),
    ]);
    board.applySwap(a, b);
    candyMap[a] = cb;
    candyMap[b] = ca;

    movesLeft--;
    onStateChanged();

    await _resolveLoop(swapA: b, swapB: a);
    _busy = false;
    _checkEnd();
  }

  /// 主结算循环：消除 -> 特效 -> 下落 -> 连锁。
  Future<void> _resolveLoop({Pos? swapA, Pos? swapB}) async {
    var cascade = 1;
    while (true) {
      final ev = board.resolveClear(
        swapA: cascade == 1 ? swapA : null,
        swapB: cascade == 1 ? swapB : null,
        cascade: cascade,
      );
      if (ev == null) break;

      score += ev.score;
      onStateChanged();
      await _playClearEffects(ev);

      // 下落
      final moves = board.applyGravity();
      await _animateFalls(moves);

      cascade++;
    }

    // 死局自动洗牌
    if (!board.hasAnyMove() && status == GameStatus.playing) {
      _world.add(FloatingText(
        text: '无可消除，洗牌！',
        at: Vector2(size.x / 2, size.y / 2),
        fontSize: 26,
      ));
      Sfx.shuffleSound();
      await Future.delayed(const Duration(milliseconds: 500));
      board.shuffleUntilPlayable();
      _spawnAll();
    }
  }

  Future<void> _playClearEffects(ClearEvent ev) async {
    // 音效 & 震动强度按事件规模
    final bigEvent = ev.colorBombTriggered ||
        ev.wrapsTriggered.isNotEmpty ||
        ev.cleared.length >= 8;

    if (ev.colorBombTriggered) {
      Sfx.bomb();
      HapticFeedback.heavyImpact();
      shakeScreen(amplitude: 12, duration: 0.4);
      // 闪电链
      if (ev.cleared.length > 1) {
        final from = cellCenter(ev.cleared.first);
        final targets =
            ev.cleared.skip(1).take(12).map(cellCenter).toList();
        _world.add(LightningEffect(from: from, targets: targets));
      }
    } else if (ev.wrapsTriggered.isNotEmpty) {
      Sfx.wrap();
      HapticFeedback.heavyImpact();
      shakeScreen(amplitude: 9, duration: 0.3);
    } else if (ev.stripesTriggered.isNotEmpty) {
      Sfx.stripe();
      HapticFeedback.mediumImpact();
      shakeScreen(amplitude: 5, duration: 0.2);
    } else {
      Sfx.pop(ev.cascade);
      HapticFeedback.lightImpact();
      if (ev.cleared.length >= 5) shakeScreen(amplitude: 3, duration: 0.15);
    }

    // 条纹光束
    for (final p in ev.stripesTriggered) {
      final cell = candyMap[p]?.cell;
      final horizontal = cell?.special != SpecialType.stripedV;
      _world.add(BeamEffect(
        center: cellCenter(p),
        horizontal: horizontal,
        length: (horizontal ? cols : rows) * cellSize * 1.1,
        thickness: cellSize * 0.7,
      ));
    }
    // 包装糖冲击波
    for (final p in ev.wrapsTriggered) {
      _world.add(ShockwaveEffect(
        center: cellCenter(p),
        maxRadius: cellSize * 2.2,
      ));
    }

    // 连锁飘字
    if (ev.cascade >= 2 && ev.cleared.isNotEmpty) {
      final words = ['好！', '妙极了！', '太棒了！', '无敌连锁!'];
      final word = words[min(ev.cascade - 2, words.length - 1)];
      final at = cellCenter(ev.cleared[ev.cleared.length ~/ 2]);
      _world.add(FloatingText(
        text: '$word x${ev.cascade}',
        at: at,
        color: const Color(0xFFFFE066),
        fontSize: 30 + min(ev.cascade * 2, 10).toDouble(),
      ));
    }

    // 得分飘字
    if (ev.score > 0 && ev.cleared.isNotEmpty) {
      _world.add(FloatingText(
        text: '+${ev.score}',
        at: cellCenter(ev.cleared.first) - Vector2(0, cellSize * 0.4),
        fontSize: 22,
        color: const Color(0xFFFFFFFF),
      ));
    }

    // 爆裂粒子 + 消除动画（大规模消除时按比例限流粒子数）
    final perCandy =
        (72 / max(6, ev.cleared.length)).clamp(4.0, 12.0).round();
    final futures = <Future<void>>[];
    for (final p in ev.cleared) {
      final comp = candyMap.remove(p);
      if (comp == null) continue;
      _world.add(burstParticles(
        comp.position.clone(),
        comp.cell.color,
        cellSize,
        intensity: bigEvent ? 1.4 : 1,
        count: perCandy,
      ));
      futures.add(comp.playClear().then((_) => comp.removeFromParent()));
    }

    // 特殊糖变身动画
    for (final entry in ev.spawns.entries) {
      final comp = candyMap[entry.key];
      if (comp != null) {
        futures.add(comp.playSpawnSpecial(entry.value));
      }
    }

    await Future.wait(futures);
  }

  Future<void> _animateFalls(List<FallMove> moves) async {
    final futures = <Future<void>>[];
    // 先重建 candyMap 映射
    final newMap = <Pos, CandyComponent>{};
    final moved = <CandyComponent>{};

    for (final m in moves) {
      if (m.from != null) {
        final comp = candyMap.remove(m.from);
        if (comp != null) {
          newMap[m.to] = comp;
          moved.add(comp);
          futures.add(comp.fallToGrid(m.to));
        }
      } else {
        // 新生成：从棋盘顶部上方掉入
        final comp = CandyComponent(
          cell: m.cell,
          gridPos: m.to,
          cellSize: cellSize,
        )..position = Vector2(
            cellCenter(m.to).x,
            boardOrigin.y - cellSize * (1.2 + m.to.row * 0.15),
          );
        comp.playSpawnIn();
        newMap[m.to] = comp;
        _world.add(comp);
        futures.add(comp.fallToGrid(m.to));
      }
    }
    // 未移动的保留
    candyMap.forEach((p, c) => newMap[p] = c);
    candyMap
      ..clear()
      ..addAll(newMap);

    await Future.wait(futures);
  }

  // ---------- 道具 ----------

  void armBooster(BoosterType type) {
    if (_busy || status != GameStatus.playing) return;
    if ((boosterCounts[type] ?? 0) <= 0) return;
    if (type == BoosterType.shuffle) {
      _useShuffle();
      return;
    }
    armedBooster = armedBooster == type ? null : type;
    _select(null);
    onStateChanged();
  }

  Future<void> _useShuffle() async {
    _busy = true;
    boosterCounts[BoosterType.shuffle] =
        boosterCounts[BoosterType.shuffle]! - 1;
    onStateChanged();
    Sfx.shuffleSound();
    board.shuffleUntilPlayable();
    _spawnAll();
    _busy = false;
  }

  Future<void> _useBoosterAt(BoosterType type, Pos p) async {
    _busy = true;
    armedBooster = null;
    boosterCounts[type] = boosterCounts[type]! - 1;
    onStateChanged();

    if (type == BoosterType.hammer) {
      HapticFeedback.mediumImpact();
      shakeScreen(amplitude: 5, duration: 0.2);
      Sfx.pop(1);
    } else {
      HapticFeedback.heavyImpact();
      shakeScreen(amplitude: 10, duration: 0.35);
      Sfx.bomb();
      _world.add(ShockwaveEffect(
        center: cellCenter(p),
        maxRadius: cellSize * 2.4,
      ));
    }

    final ev = board.useBooster(type, p);
    score += ev.score;
    await _playClearEffects(ev);
    final moves = board.applyGravity();
    await _animateFalls(moves);
    await _resolveLoop();
    _busy = false;
    _checkEnd();
  }

  // ---------- 胜负 ----------

  void _checkEnd() {
    if (status != GameStatus.playing) return;
    if (score >= level.targetScore && movesLeft >= 0) {
      status = GameStatus.won;
      Sfx.win();
      _celebrate();
    } else if (movesLeft <= 0) {
      status = score >= level.targetScore ? GameStatus.won : GameStatus.lost;
      if (status == GameStatus.won) {
        Sfx.win();
        _celebrate();
      } else {
        Sfx.lose();
      }
    }
    onStateChanged();
  }

  void _celebrate() {
    // 全屏彩带粒子
    for (var i = 0; i < 5; i++) {
      final x = size.x * (0.15 + 0.175 * i);
      _world.add(burstParticles(
        Vector2(x, size.y * 0.3),
        CandyColor.values[i % CandyColor.values.length],
        cellSize,
        intensity: 2,
      ));
    }
    shakeScreen(amplitude: 6, duration: 0.3);
  }

  int get stars {
    if (score >= level.starScore(3)) return 3;
    if (score >= level.starScore(2)) return 2;
    if (score >= level.starScore(1)) return 1;
    return 0;
  }
}

/// 棋盘底板：玻璃拟态面板 + 带内凹感的格子。
class _BoardBackground extends PositionComponent {
  _BoardBackground({
    required this.origin,
    required this.cellSize,
    required this.rows,
    required this.cols,
  }) : super(priority: -10);

  final Vector2 origin;
  final double cellSize;
  final int rows;
  final int cols;

  @override
  void render(Canvas canvas) {
    final pad = cellSize * 0.16;
    final boardRect = Rect.fromLTWH(
      origin.x - pad,
      origin.y - pad,
      cellSize * cols + pad * 2,
      cellSize * rows + pad * 2,
    );
    final rrect = RRect.fromRectAndRadius(
      boardRect,
      Radius.circular(cellSize * 0.42),
    );

    // 面板落影
    canvas.drawRRect(
      rrect.shift(const Offset(0, 10)),
      Paint()
        ..color = const Color(0x59000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // 面板主体（深紫玻璃渐变）
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = Gradient.linear(
          boardRect.topCenter,
          boardRect.bottomCenter,
          [const Color(0xE6241543), const Color(0xE61A0F33)],
        ),
    );
    // 顶部内侧亮边 + 底部暗边（体积感）
    canvas.drawRRect(
      rrect.deflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..shader = Gradient.linear(
          boardRect.topCenter,
          boardRect.bottomCenter,
          [const Color(0x66FFFFFF), const Color(0x11FFFFFF), const Color(0x33000000)],
          const [0.0, 0.35, 1.0],
        ),
    );

    // 格子：交错明暗 + 每格顶部微亮线，营造内凹托盘感
    final cellLight = Paint()..color = const Color(0x21FFFFFF);
    final cellDark = Paint()..color = const Color(0x0DFFFFFF);
    final cellEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x14FFFFFF);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          origin.x + c * cellSize,
          origin.y + r * cellSize,
          cellSize,
          cellSize,
        ).deflate(cellSize * 0.035);
        final cell = RRect.fromRectAndRadius(
          rect,
          Radius.circular(cellSize * 0.22),
        );
        canvas.drawRRect(cell, (r + c).isEven ? cellLight : cellDark);
        canvas.drawRRect(cell, cellEdge);
      }
    }
  }
}
