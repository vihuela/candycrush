import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_crush/game/board.dart';
import 'package:sweet_crush/game/candy_spec.dart';

void main() {
  test('initial board has no matches and has moves', () {
    for (var seed = 0; seed < 30; seed++) {
      final b = Board(8, 8, rng: Random(seed));
      expect(b.hasAnyMove(), isTrue, reason: 'seed $seed');
      final ev = b.resolveClear(cascade: 1);
      expect(ev, isNull, reason: 'seed $seed should start with no matches');
    }
  });

  test('swap, clear, gravity keeps board full', () {
    final b = Board(8, 8, rng: Random(42));
    // 找到一步合法交换
    Pos? a, bb;
    outer:
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        for (final d in const [Pos(0, 1), Pos(1, 0)]) {
          final q = Pos(r + d.row, c + d.col);
          if (b.inBounds(q) && b.isValidSwap(Pos(r, c), q)) {
            a = Pos(r, c);
            bb = q;
            break outer;
          }
        }
      }
    }
    expect(a, isNotNull);
    b.applySwap(a!, bb!);
    var cascade = 1;
    while (true) {
      final ev = b.resolveClear(
        swapA: cascade == 1 ? a : null,
        swapB: cascade == 1 ? bb : null,
        cascade: cascade,
      );
      if (ev == null) break;
      expect(ev.score, greaterThan(0));
      b.applyGravity();
      cascade++;
    }
    // 棋盘应满
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        expect(b.at(Pos(r, c)), isNotNull);
      }
    }
  });

  test('striped candy spawn on 4-match', () {
    final b = Board(5, 5, rng: Random(1), colorCount: 3);
    // 手工构造一行 4 连:  R R _ R R -> 中间换成 R 不行，直接摆好后触发
    final red = CandyColor.red;
    final other = CandyColor.blue;
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        b.grid[r][c] = Cell(other);
      }
    }
    // 防止 other 自身成三连: 打散
    b.grid[0][0] = Cell(CandyColor.green);
    b.grid[0][3] = Cell(CandyColor.green);
    b.grid[2][2] = Cell(CandyColor.green);
    b.grid[2][4] = Cell(CandyColor.green);
    b.grid[3][0] = Cell(CandyColor.green);
    b.grid[3][3] = Cell(CandyColor.green);
    b.grid[4][1] = Cell(CandyColor.green);
    b.grid[4][4] = Cell(CandyColor.green);
    // 第2行: R R R R
    for (var c = 0; c < 4; c++) {
      b.grid[1][c] = Cell(red);
    }
    final ev = b.resolveClear(swapA: const Pos(1, 1), cascade: 1);
    expect(ev, isNotNull);
    expect(ev!.spawns.length, 1);
    expect(ev.spawns.values.first, SpecialType.stripedV);
  });

  test('color bomb clears same color', () {
    final b = Board(5, 5, rng: Random(3), colorCount: 3);
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        b.grid[r][c] =
            Cell(CandyColor.values[(r * 5 + c) % 3]);
      }
    }
    b.grid[2][2] = Cell(CandyColor.red, special: SpecialType.colorBomb);
    b.grid[2][3] = Cell(CandyColor.blue);
    expect(b.isValidSwap(const Pos(2, 2), const Pos(2, 3)), isTrue);
    b.applySwap(const Pos(2, 2), const Pos(2, 3));
    final ev = b.resolveClear(
      swapA: const Pos(2, 3),
      swapB: const Pos(2, 2),
      cascade: 1,
    );
    expect(ev, isNotNull);
    expect(ev!.colorBombTriggered, isTrue);
    // 所有蓝色都应被清除
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        expect(b.grid[r][c]?.color, isNot(CandyColor.blue));
      }
    }
  });

  test('shuffle keeps playable', () {
    final b = Board(8, 8, rng: Random(7));
    b.shuffleUntilPlayable();
    expect(b.hasAnyMove(), isTrue);
  });
}
