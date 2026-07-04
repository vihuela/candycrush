import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/painting.dart' show Canvas, Paint, Color, Offset;

import 'board.dart';
import 'candy_painter.dart';
import 'candy_spec.dart';
import 'match_game.dart';

/// 单颗糖果的渲染组件。
class CandyComponent extends PositionComponent
    with HasGameReference<MatchGame> {
  CandyComponent({
    required this.cell,
    required this.gridPos,
    required double cellSize,
  }) : super(
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
        );

  Cell cell;
  Pos gridPos;
  bool selected = false;
  double _pulse = 0;
  double _idlePhase = Random().nextDouble() * 2 * pi;

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt;
    _idlePhase += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    if (selected) {
      // 选中：呼吸放大 + 光圈
      final s = 1.0 + 0.08 * sin(_pulse * 8);
      canvas.drawCircle(
        Offset.zero,
        size.x * 0.52,
        Paint()..color = const Color(0x66FFFFFF),
      );
      canvas.scale(s);
    } else if (cell.special == SpecialType.colorBomb) {
      // 彩球常态微旋转
      canvas.rotate(sin(_idlePhase * 1.5) * 0.12);
    } else if (cell.isSpecial) {
      // 特殊糖微微脉动提示
      final s = 1.0 + 0.04 * sin(_idlePhase * 3);
      canvas.scale(s);
    }

    CandyPainter.paint(canvas, size.x, cell.color, cell.special);
    canvas.restore();
  }

  /// 移动到网格位置。
  Future<void> moveToGrid(Pos p, {double speed = 6, Curve? curve}) {
    gridPos = p;
    final target = game.cellCenter(p);
    final dist = (target - position).length;
    final duration = (dist / (size.x * speed)).clamp(0.06, 0.5);
    final completer = MoveToEffect(
      target,
      EffectController(
        duration: duration,
        curve: curve ?? Curves.easeInOut,
      ),
    );
    add(completer);
    return completer.completed;
  }

  /// 下落 + 落地小弹跳。
  Future<void> fallToGrid(Pos p) async {
    gridPos = p;
    final target = game.cellCenter(p);
    final dist = (target - position).length;
    final duration = (0.10 + dist / (size.x * 22)).clamp(0.12, 0.42);
    final move = MoveToEffect(
      target,
      EffectController(duration: duration, curve: Curves.easeInQuad),
    );
    add(move);
    await move.completed;
    // 落地挤压弹跳
    final squash = SequenceEffect([
      ScaleEffect.to(
        Vector2(1.12, 0.86),
        EffectController(duration: 0.06),
      ),
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.12, curve: Curves.elasticOut),
      ),
    ]);
    add(squash);
    await squash.completed;
  }

  /// 无效交换的抖头动画。
  Future<void> shake() async {
    final effect = SequenceEffect([
      MoveByEffect(Vector2(6, 0), EffectController(duration: 0.04)),
      MoveByEffect(Vector2(-12, 0), EffectController(duration: 0.08)),
      MoveByEffect(Vector2(12, 0), EffectController(duration: 0.08)),
      MoveByEffect(Vector2(-6, 0), EffectController(duration: 0.04)),
    ]);
    add(effect);
    await effect.completed;
  }

  /// 消除动画：放大后缩没。
  Future<void> playClear() async {
    final effect = SequenceEffect([
      ScaleEffect.to(Vector2.all(1.25), EffectController(duration: 0.08)),
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.16, curve: Curves.easeInBack),
      ),
    ]);
    add(effect);
    await effect.completed;
  }

  /// 变身特殊糖动画。
  Future<void> playSpawnSpecial(SpecialType type) async {
    cell.special = type;
    final effect = SequenceEffect([
      ScaleEffect.to(Vector2.all(1.5), EffectController(duration: 0.12)),
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.25, curve: Curves.bounceOut),
      ),
    ]);
    add(effect);
    await effect.completed;
  }

  /// 顶部生成新糖时的入场缩放。
  void playSpawnIn() {
    scale = Vector2.all(0.3);
    add(ScaleEffect.to(
      Vector2.all(1),
      EffectController(duration: 0.18, curve: Curves.easeOut),
    ));
  }
}
