import 'dart:math';

import 'candy_spec.dart';

/// 棋盘上的一颗糖果（纯数据）。
class Cell {
  Cell(this.color, {this.special = SpecialType.none});

  CandyColor color;
  SpecialType special;

  bool get isSpecial => special != SpecialType.none;
}

class Pos {
  const Pos(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is Pos && other.row == row && other.col == col;

  @override
  int get hashCode => row * 100 + col;

  @override
  String toString() => '($row,$col)';
}

/// 一次消除结算中的事件，渲染层据此播放动画。
class ClearEvent {
  ClearEvent({
    required this.cleared,
    required this.spawns,
    required this.score,
    required this.cascade,
    this.colorBombTriggered = false,
    this.stripesTriggered = const [],
    this.wrapsTriggered = const [],
  });

  /// 被消除的格子。
  final List<Pos> cleared;

  /// 本次生成的特殊糖果（位置 -> 类型）。
  final Map<Pos, SpecialType> spawns;

  final int score;

  /// 连锁层级，1 表示玩家直接触发。
  final int cascade;

  final bool colorBombTriggered;
  final List<Pos> stripesTriggered;
  final List<Pos> wrapsTriggered;
}

/// 下落移动：from 可能为 null（表示从顶部新生成）。
class FallMove {
  FallMove({this.from, required this.to, required this.cell});

  final Pos? from;
  final Pos to;
  final Cell cell;
}

/// 消消乐棋盘核心逻辑，纯 Dart 无渲染依赖，方便单测。
class Board {
  Board(this.rows, this.cols, {Random? rng, int colorCount = 6})
      : _rng = rng ?? Random(),
        _colorCount = colorCount.clamp(3, CandyColor.values.length) {
    _fillInitial();
  }

  final int rows;
  final int cols;
  final Random _rng;
  final int _colorCount;

  late List<List<Cell?>> grid;

  Cell? at(Pos p) => grid[p.row][p.col];

  bool inBounds(Pos p) =>
      p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols;

  CandyColor _randColor() => CandyColor.values[_rng.nextInt(_colorCount)];

  /// 初始填充，保证无现成三连、且至少存在一步可消除。
  void _fillInitial() {
    for (var attempt = 0; attempt < 50; attempt++) {
      grid = List.generate(
        rows,
        (r) => List<Cell?>.generate(cols, (c) => Cell(_randColor())),
      );
      _removeInitialMatches();
      if (hasAnyMove()) return;
    }
    // 兜底：极小概率走到这里，直接洗到有解。
    shuffleUntilPlayable();
  }

  void _removeInitialMatches() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        var guard = 0;
        while (_formsMatchAt(r, c) && guard < 20) {
          grid[r][c] = Cell(_randColor());
          guard++;
        }
      }
    }
  }

  bool _formsMatchAt(int r, int c) {
    final color = grid[r][c]!.color;
    if (c >= 2 &&
        grid[r][c - 1]?.color == color &&
        grid[r][c - 2]?.color == color) {
      return true;
    }
    if (r >= 2 &&
        grid[r - 1][c]?.color == color &&
        grid[r - 2][c]?.color == color) {
      return true;
    }
    return false;
  }

  // ---------- 交换 ----------

  bool areAdjacent(Pos a, Pos b) =>
      (a.row - b.row).abs() + (a.col - b.col).abs() == 1;

  /// 交换是否合法（能触发消除或含特殊糖组合）。
  bool isValidSwap(Pos a, Pos b) {
    if (!areAdjacent(a, b)) return false;
    final ca = at(a);
    final cb = at(b);
    if (ca == null || cb == null) return false;
    // 彩球与任意糖交换都合法；两个特殊糖组合也合法。
    if (ca.special == SpecialType.colorBomb ||
        cb.special == SpecialType.colorBomb) {
      return true;
    }
    if (ca.isSpecial && cb.isSpecial) return true;
    _swap(a, b);
    final ok = _findMatches().isNotEmpty;
    _swap(a, b);
    return ok;
  }

  void _swap(Pos a, Pos b) {
    final tmp = grid[a.row][a.col];
    grid[a.row][a.col] = grid[b.row][b.col];
    grid[b.row][b.col] = tmp;
  }

  void applySwap(Pos a, Pos b) => _swap(a, b);

  // ---------- 匹配检测 ----------

  /// 找出所有连成 3+ 的组（横竖分组，用于特殊糖生成判断）。
  List<List<Pos>> _findMatchGroups() {
    final groups = <List<Pos>>[];
    // 横向
    for (var r = 0; r < rows; r++) {
      var c = 0;
      while (c < cols) {
        final cell = grid[r][c];
        if (cell == null) {
          c++;
          continue;
        }
        var end = c + 1;
        while (end < cols && grid[r][end]?.color == cell.color) {
          end++;
        }
        if (end - c >= 3) {
          groups.add([for (var i = c; i < end; i++) Pos(r, i)]);
        }
        c = end;
      }
    }
    // 纵向
    for (var c = 0; c < cols; c++) {
      var r = 0;
      while (r < rows) {
        final cell = grid[r][c];
        if (cell == null) {
          r++;
          continue;
        }
        var end = r + 1;
        while (end < rows && grid[end][c]?.color == cell.color) {
          end++;
        }
        if (end - r >= 3) {
          groups.add([for (var i = r; i < end; i++) Pos(i, c)]);
        }
        r = end;
      }
    }
    return groups;
  }

  Set<Pos> _findMatches() {
    final s = <Pos>{};
    for (final g in _findMatchGroups()) {
      s.addAll(g);
    }
    return s;
  }

  // ---------- 消除结算 ----------

  /// 执行一轮消除。[swapA]/[swapB] 是刚发生的交换位置（用于确定特殊糖生成点
  /// 和特殊糖组合判定）；连锁轮传 null。返回 null 表示没有可消除的。
  ClearEvent? resolveClear({Pos? swapA, Pos? swapB, required int cascade}) {
    // 1. 特殊糖组合（仅在玩家交换时触发）
    if (swapA != null && swapB != null) {
      final combo = _tryComboClear(swapA, swapB, cascade);
      if (combo != null) return combo;
    }

    final groups = _findMatchGroups();
    if (groups.isEmpty) return null;

    final toClear = <Pos>{};
    final spawns = <Pos, SpecialType>{};

    // 2. 特殊糖生成判定
    final merged = _mergeGroups(groups);
    for (final group in merged) {
      toClear.addAll(group.cells);
      final spawnType = group.spawnType;
      if (spawnType != SpecialType.none) {
        // 优先生成在交换点上，否则生成在组中心。
        Pos spawnAt = group.cells[group.cells.length ~/ 2];
        for (final p in [swapA, swapB]) {
          if (p != null && group.cells.contains(p)) {
            spawnAt = p;
            break;
          }
        }
        spawns[spawnAt] = spawnType;
      }
    }

    // 3. 引爆被波及的特殊糖（链式）
    final stripes = <Pos>[];
    final wraps = <Pos>[];
    _expandSpecials(toClear, stripes, wraps);

    // 4. 计分：基础 60/颗，特殊糖 +120，连锁翻倍
    var score = 0;
    for (final p in toClear) {
      final cell = at(p);
      if (cell == null) continue;
      score += cell.isSpecial ? 180 : 60;
    }
    score *= cascade;

    // 5. 移除（生成点不移除，替换为特殊糖）
    for (final p in toClear) {
      if (spawns.containsKey(p)) {
        grid[p.row][p.col] = Cell(at(p)!.color, special: spawns[p]!);
      } else {
        grid[p.row][p.col] = null;
      }
    }

    return ClearEvent(
      cleared: toClear.where((p) => !spawns.containsKey(p)).toList(),
      spawns: spawns,
      score: score,
      cascade: cascade,
      stripesTriggered: stripes,
      wrapsTriggered: wraps,
    );
  }

  /// 特殊糖 + 特殊糖 / 彩球组合。
  ClearEvent? _tryComboClear(Pos a, Pos b, int cascade) {
    final ca = at(a);
    final cb = at(b);
    if (ca == null || cb == null) return null;

    final aBomb = ca.special == SpecialType.colorBomb;
    final bBomb = cb.special == SpecialType.colorBomb;

    final toClear = <Pos>{};
    final stripes = <Pos>[];
    final wraps = <Pos>[];
    var colorBomb = false;

    if (aBomb && bBomb) {
      // 双彩球：全屏清除
      colorBomb = true;
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (grid[r][c] != null) toClear.add(Pos(r, c));
        }
      }
    } else if (aBomb || bBomb) {
      colorBomb = true;
      final bombPos = aBomb ? a : b;
      final other = aBomb ? cb : ca;
      final otherPos = aBomb ? b : a;
      toClear.add(bombPos);
      if (other.isSpecial) {
        // 彩球+条纹/包装：把所有同色糖变成该特殊糖并引爆
        for (var r = 0; r < rows; r++) {
          for (var c = 0; c < cols; c++) {
            final cell = grid[r][c];
            if (cell != null && cell.color == other.color) {
              cell.special = other.special;
              toClear.add(Pos(r, c));
            }
          }
        }
      } else {
        // 彩球+普通：清同色
        for (var r = 0; r < rows; r++) {
          for (var c = 0; c < cols; c++) {
            final cell = grid[r][c];
            if (cell != null && cell.color == other.color) {
              toClear.add(Pos(r, c));
            }
          }
        }
        toClear.add(otherPos);
      }
    } else if (ca.isSpecial && cb.isSpecial) {
      // 条纹+条纹：十字；包装+条纹：3行3列；包装+包装：5x5
      final bothWrapped =
          ca.special == SpecialType.wrapped && cb.special == SpecialType.wrapped;
      final bothStriped = !bothWrapped &&
          ca.special != SpecialType.wrapped &&
          cb.special != SpecialType.wrapped;
      if (bothStriped) {
        _clearRow(b.row, toClear);
        _clearCol(b.col, toClear);
        stripes.add(b);
      } else if (bothWrapped) {
        _clearBlock(b, 2, toClear);
        wraps.addAll([a, b]);
      } else {
        for (var dr = -1; dr <= 1; dr++) {
          _clearRow(b.row + dr, toClear);
        }
        for (var dc = -1; dc <= 1; dc++) {
          _clearCol(b.col + dc, toClear);
        }
        stripes.add(b);
        wraps.add(b);
      }
      toClear.addAll([a, b]);
    } else {
      return null;
    }

    _expandSpecials(toClear, stripes, wraps);

    var score = 0;
    for (final p in toClear) {
      if (at(p) != null) score += 120;
    }
    score *= cascade;

    for (final p in toClear) {
      grid[p.row][p.col] = null;
    }

    return ClearEvent(
      cleared: toClear.toList(),
      spawns: const {},
      score: score,
      cascade: cascade,
      colorBombTriggered: colorBomb,
      stripesTriggered: stripes,
      wrapsTriggered: wraps,
    );
  }

  void _clearRow(int r, Set<Pos> out) {
    if (r < 0 || r >= rows) return;
    for (var c = 0; c < cols; c++) {
      if (grid[r][c] != null) out.add(Pos(r, c));
    }
  }

  void _clearCol(int c, Set<Pos> out) {
    if (c < 0 || c >= cols) return;
    for (var r = 0; r < rows; r++) {
      if (grid[r][c] != null) out.add(Pos(r, c));
    }
  }

  void _clearBlock(Pos center, int radius, Set<Pos> out) {
    for (var r = center.row - radius; r <= center.row + radius; r++) {
      for (var c = center.col - radius; c <= center.col + radius; c++) {
        final p = Pos(r, c);
        if (inBounds(p) && grid[r][c] != null) out.add(p);
      }
    }
  }

  /// 链式引爆：消除范围内的特殊糖会扩大消除范围。
  void _expandSpecials(Set<Pos> toClear, List<Pos> stripes, List<Pos> wraps) {
    final queue = List<Pos>.from(toClear);
    final processed = <Pos>{};
    while (queue.isNotEmpty) {
      final p = queue.removeLast();
      if (!processed.add(p)) continue;
      final cell = at(p);
      if (cell == null) continue;
      Set<Pos> extra = {};
      switch (cell.special) {
        case SpecialType.stripedH:
          _clearRow(p.row, extra);
          stripes.add(p);
        case SpecialType.stripedV:
          _clearCol(p.col, extra);
          stripes.add(p);
        case SpecialType.wrapped:
          _clearBlock(p, 1, extra);
          wraps.add(p);
        case SpecialType.colorBomb:
          // 被动引爆的彩球：清除场上最多的颜色
          final counts = <CandyColor, int>{};
          for (var r = 0; r < rows; r++) {
            for (var c = 0; c < cols; c++) {
              final cc = grid[r][c];
              if (cc != null && !toClear.contains(Pos(r, c))) {
                counts[cc.color] = (counts[cc.color] ?? 0) + 1;
              }
            }
          }
          if (counts.isNotEmpty) {
            final target = counts.entries
                .reduce((x, y) => x.value >= y.value ? x : y)
                .key;
            for (var r = 0; r < rows; r++) {
              for (var c = 0; c < cols; c++) {
                if (grid[r][c]?.color == target) extra.add(Pos(r, c));
              }
            }
          }
        case SpecialType.none:
          break;
      }
      for (final e in extra) {
        if (toClear.add(e)) queue.add(e);
      }
    }
  }

  // ---------- 特殊糖生成规则 ----------

  List<_MergedGroup> _mergeGroups(List<List<Pos>> groups) {
    // 合并共享格子的横竖组（L/T 形 -> 包装糖）
    final merged = <_MergedGroup>[];
    final used = List<bool>.filled(groups.length, false);
    for (var i = 0; i < groups.length; i++) {
      if (used[i]) continue;
      final cells = <Pos>{...groups[i]};
      var isCross = false;
      var maxLen = groups[i].length;
      final horizontal = groups[i].length >= 2 &&
          groups[i][0].row == groups[i][1].row;
      for (var j = i + 1; j < groups.length; j++) {
        if (used[j]) continue;
        if (groups[j].any(cells.contains)) {
          cells.addAll(groups[j]);
          used[j] = true;
          isCross = true;
          maxLen = max(maxLen, groups[j].length);
        }
      }
      used[i] = true;

      SpecialType spawn;
      if (isCross) {
        spawn = SpecialType.wrapped;
      } else if (maxLen >= 5) {
        spawn = SpecialType.colorBomb;
      } else if (maxLen == 4) {
        spawn = horizontal ? SpecialType.stripedV : SpecialType.stripedH;
      } else {
        spawn = SpecialType.none;
      }
      merged.add(_MergedGroup(cells.toList(), spawn));
    }
    return merged;
  }

  // ---------- 重力与填充 ----------

  /// 应用重力并从顶部补新糖，返回所有移动供动画使用。
  List<FallMove> applyGravity() {
    final moves = <FallMove>[];
    for (var c = 0; c < cols; c++) {
      var writeRow = rows - 1;
      for (var r = rows - 1; r >= 0; r--) {
        final cell = grid[r][c];
        if (cell != null) {
          if (r != writeRow) {
            grid[writeRow][c] = cell;
            grid[r][c] = null;
            moves.add(
              FallMove(from: Pos(r, c), to: Pos(writeRow, c), cell: cell),
            );
          }
          writeRow--;
        }
      }
      // 顶部补新糖
      for (var r = writeRow; r >= 0; r--) {
        final cell = Cell(_randColor());
        grid[r][c] = cell;
        moves.add(FallMove(from: null, to: Pos(r, c), cell: cell));
      }
    }
    return moves;
  }

  // ---------- 死局检测与洗牌 ----------

  bool hasAnyMove() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (grid[r][c]?.special == SpecialType.colorBomb) return true;
        final p = Pos(r, c);
        for (final d in const [Pos(0, 1), Pos(1, 0)]) {
          final q = Pos(r + d.row, c + d.col);
          if (!inBounds(q)) continue;
          if (grid[q.row][q.col] == null || grid[r][c] == null) continue;
          _swap(p, q);
          final ok = _findMatches().isNotEmpty;
          _swap(p, q);
          if (ok) return true;
        }
      }
    }
    return false;
  }

  /// 洗牌直到有解且无现成三连。
  void shuffleUntilPlayable() {
    final cells = <Cell>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (grid[r][c] != null) cells.add(grid[r][c]!);
      }
    }
    for (var attempt = 0; attempt < 100; attempt++) {
      cells.shuffle(_rng);
      var i = 0;
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (grid[r][c] != null) grid[r][c] = cells[i++];
        }
      }
      if (_findMatches().isEmpty && hasAnyMove()) return;
    }
  }

  // ---------- 道具 ----------

  /// 锤子：敲碎单颗。炸弹：3x3。返回消除事件。
  ClearEvent useBooster(BoosterType type, Pos target) {
    final toClear = <Pos>{};
    final stripes = <Pos>[];
    final wraps = <Pos>[];
    switch (type) {
      case BoosterType.hammer:
        if (at(target) != null) toClear.add(target);
      case BoosterType.bomb:
        _clearBlock(target, 1, toClear);
        wraps.add(target);
      case BoosterType.shuffle:
        shuffleUntilPlayable();
        return ClearEvent(
          cleared: const [],
          spawns: const {},
          score: 0,
          cascade: 1,
        );
    }
    _expandSpecials(toClear, stripes, wraps);
    var score = 0;
    for (final p in toClear) {
      if (at(p) != null) score += 60;
    }
    for (final p in toClear) {
      grid[p.row][p.col] = null;
    }
    return ClearEvent(
      cleared: toClear.toList(),
      spawns: const {},
      score: score,
      cascade: 1,
      stripesTriggered: stripes,
      wrapsTriggered: wraps,
    );
  }
}

class _MergedGroup {
  _MergedGroup(this.cells, this.spawnType);

  final List<Pos> cells;
  final SpecialType spawnType;
}
