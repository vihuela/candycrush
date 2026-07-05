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

  test('holes never filled, gravity segments around cookie', () {
    final b = Board(
      8, 8,
      rng: Random(5),
      holes: {const Pos(0, 0), const Pos(0, 1)},
      cookieCells: {const Pos(4, 3)},
    );
    expect(b.at(const Pos(0, 0)), isNull);
    expect(b.at(const Pos(4, 3)), isNull);
    expect(b.obstacleAt(const Pos(4, 3)), ObstacleType.cookie);
    // 制造消除后重力，多轮后洞和饼干格仍为空
    for (var i = 0; i < 5; i++) {
      b.grid[6][3] = null;
      b.grid[2][3] = null;
      b.applyGravity();
    }
    expect(b.at(const Pos(0, 0)), isNull);
    expect(b.at(const Pos(4, 3)), isNull);
    // 其余格子应满
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = Pos(r, c);
        if (b.isHole(p) || b.obstacleAt(p) == ObstacleType.cookie) continue;
        expect(b.at(p), isNotNull, reason: '$p should be filled');
      }
    }
  });

  test('ice blocks swap and breaks instead of clearing', () {
    final b = Board(5, 5, rng: Random(2), colorCount: 3,
        iceCells: {const Pos(1, 1)});
    expect(b.isValidSwap(const Pos(1, 1), const Pos(1, 2)), isFalse);
    // 构造包含冰冻格的三连
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        b.grid[r][c] = Cell(CandyColor.values[(r * 2 + c) % 3]);
      }
    }
    b.grid[1][0] = Cell(CandyColor.red);
    b.grid[1][1] = Cell(CandyColor.red);
    b.grid[1][2] = Cell(CandyColor.red);
    // 打散意外三连
    b.grid[0][0] = Cell(CandyColor.green);
    b.grid[0][1] = Cell(CandyColor.blue);
    b.grid[0][2] = Cell(CandyColor.green);
    b.grid[2][0] = Cell(CandyColor.blue);
    b.grid[2][1] = Cell(CandyColor.green);
    b.grid[2][2] = Cell(CandyColor.blue);
    final ev = b.resolveClear(cascade: 1);
    expect(ev, isNotNull);
    expect(ev!.iceBroken, contains(const Pos(1, 1)));
    // 冰保住了糖：冰格糖果还在
    expect(b.at(const Pos(1, 1)), isNotNull);
    expect(b.at(const Pos(1, 0)), isNull);
    expect(b.obstacleAt(const Pos(1, 1)), ObstacleType.none);
  });

  test('cookie breaks from adjacent clear', () {
    final b = Board(5, 5, rng: Random(4), colorCount: 3,
        cookieCells: {const Pos(2, 3)});
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        if (b.obstacleAt(Pos(r, c)) != ObstacleType.cookie) {
          b.grid[r][c] = Cell(CandyColor.values[(r * 2 + c) % 3]);
        }
      }
    }
    // (2,0)(2,1)(2,2) 三连，紧邻饼干 (2,3)
    b.grid[2][0] = Cell(CandyColor.red);
    b.grid[2][1] = Cell(CandyColor.red);
    b.grid[2][2] = Cell(CandyColor.red);
    b.grid[1][0] = Cell(CandyColor.green);
    b.grid[1][1] = Cell(CandyColor.blue);
    b.grid[1][2] = Cell(CandyColor.green);
    b.grid[3][0] = Cell(CandyColor.blue);
    b.grid[3][1] = Cell(CandyColor.green);
    b.grid[3][2] = Cell(CandyColor.blue);
    final ev = b.resolveClear(cascade: 1);
    expect(ev, isNotNull);
    expect(ev!.cookiesBroken, contains(const Pos(2, 3)));
    expect(b.obstacleAt(const Pos(2, 3)), ObstacleType.none);
  });
}
