// Google Play 商店提审图生成器。
//
// 复用游戏内的矢量渲染（CandyPainter / 调色板 / Fredoka 字体）排版宣传图，
// 保证提审图与游戏实际美术完全一致。运行：
//
//   STORE_SHOTS=1 flutter test test/store_screenshots_test.dart
//
// 产出（PNG 母版，后续用 sips 转无 Alpha 的 JPEG）：
//   store_submission/masters_png/*.png
//     - 竖图 4 张 1080x1920，横图 2 张 1920x1080
//     - Feature Graphic 1024x500（Play 上架必需）
//
// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sweet_crush/game/candy_painter.dart';
import 'package:sweet_crush/game/candy_spec.dart';

const _outDir = 'store_submission/masters_png';

void main() {
  final enabled = Platform.environment['STORE_SHOTS'] == '1';

  setUpAll(() async {
    final loader = FontLoader('Fredoka');
    for (final path in [
      'assets/fonts/Fredoka-SemiBold-static.ttf',
      'assets/fonts/Fredoka-Bold-static.ttf',
    ]) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();

    // Material 图标字体（HUD/道具按钮用）。flutter_tester 位于
    // $FLUTTER_ROOT/bin/cache/artifacts/engine/<platform>/，向上回溯即可。
    final engineDir = File(Platform.resolvedExecutable).parent;
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
        engineDir.parent.parent.parent.parent.path;
    final iconFont = File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (iconFont.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons')
        ..addFont(Future.value(
            ByteData.view(iconFont.readAsBytesSync().buffer)));
      await iconLoader.load();
    }
  });

  Future<void> shot(
    WidgetTester tester,
    Size size,
    String file,
    Widget child,
  ) async {
    debugDisableShadows = false;
    try {
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: size.width,
              height: size.height,
              // Material 祖先：避免 Text 出现黄色双下划线的调试样式
              child: Material(type: MaterialType.transparency, child: child),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_outDir/$file')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data!.buffer.asUint8List());
      });
    } finally {
      debugDisableShadows = true;
    }
  }

  group('store screenshots', () {
    testWidgets('portrait 1 hero', (tester) async {
      await shot(tester, const Size(1080, 1920), 'phone_portrait_1_hero.png',
          const _HeroPortrait());
    });

    testWidgets('portrait 2 gameplay', (tester) async {
      await shot(tester, const Size(1080, 1920),
          'phone_portrait_2_gameplay.png', const _GameplayPortrait());
    });

    testWidgets('portrait 3 specials', (tester) async {
      await shot(tester, const Size(1080, 1920),
          'phone_portrait_3_specials.png', const _SpecialsPortrait());
    });

    testWidgets('portrait 4 modes', (tester) async {
      await shot(tester, const Size(1080, 1920), 'phone_portrait_4_modes.png',
          const _ModesPortrait());
    });

    testWidgets('landscape 1 hero', (tester) async {
      await shot(tester, const Size(1920, 1080), 'phone_landscape_1_hero.png',
          const _HeroLandscape());
    });

    testWidgets('landscape 2 combos', (tester) async {
      await shot(tester, const Size(1920, 1080),
          'phone_landscape_2_combos.png', const _CombosLandscape());
    });

    testWidgets('feature graphic', (tester) async {
      await shot(tester, const Size(1024, 500),
          'feature_graphic_1024x500.png', const _FeatureGraphic());
    });

    testWidgets('app icon', (tester) async {
      await shot(
          tester, const Size(512, 512), 'app_icon_512.png', const _AppIcon());
    });
  }, skip: enabled ? false : 'Set STORE_SHOTS=1 to generate store images');
}

// ===========================================================================
// 通用元素
// ===========================================================================

/// 与游戏 GameBackground 一致的夜空紫背景 + 光斑点缀。
class _PromoBackground extends StatelessWidget {
  const _PromoBackground({required this.child, this.seed = 1});

  final Widget child;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B1055), Color(0xFF4A1E7E), Color(0xFF34347E)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -160,
            left: -80,
            right: -80,
            height: 460,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x38FF9FF3), Color(0x00FF9FF3)],
                ),
              ),
            ),
          ),
          CustomPaint(painter: _BokehPainter(seed)),
          child,
        ],
      ),
    );
  }
}

/// 漂浮光斑 + 远景幽灵糖果。
class _BokehPainter extends CustomPainter {
  _BokehPainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    // 光斑
    for (var i = 0; i < 26; i++) {
      final c = Offset(
          rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      final r = 5 + rng.nextDouble() * 60;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = (rng.nextBool()
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFFFB3F0))
              .withValues(alpha: 0.025 + rng.nextDouble() * 0.06)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4),
      );
    }
    // 小亮点
    for (var i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        1.5 + rng.nextDouble() * 2.5,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
    }
    // 幽灵糖果（低透明度旋转漂浮）
    final ghostColors = CandyColor.values;
    for (var i = 0; i < 7; i++) {
      final center = Offset(
          rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      final s = 46 + rng.nextDouble() * 70;
      canvas.saveLayer(
        Rect.fromCircle(center: center, radius: s * 1.6),
        Paint()..color = const Color(0x14FFFFFF),
      );
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rng.nextDouble() * pi);
      CandyPainter.paint(
          canvas, s, ghostColors[i % ghostColors.length], SpecialType.none);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BokehPainter old) => old.seed != seed;
}

/// 描边大字。
class _StrokeText extends StatelessWidget {
  const _StrokeText(
    this.text, {
    required this.fontSize,
    this.fill = Colors.white,
    this.stroke = const Color(0xFF3A1460),
    this.strokeWidth,
    this.weight = FontWeight.w700,
    this.align = TextAlign.center,
    this.height,
  });

  final String text;
  final double fontSize;
  final Color fill;
  final Color stroke;
  final double? strokeWidth;
  final FontWeight weight;
  final TextAlign align;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'Fredoka',
      fontSize: fontSize,
      fontWeight: weight,
      height: height,
      letterSpacing: 1.2,
    );
    return Stack(
      children: [
        Text(
          text,
          textAlign: align,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth ?? fontSize * 0.14
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
            shadows: [
              Shadow(
                color: const Color(0x66000000),
                offset: Offset(0, fontSize * 0.07),
                blurRadius: fontSize * 0.18,
              ),
            ],
          ),
        ),
        Text(text, textAlign: align, style: base.copyWith(color: fill)),
      ],
    );
  }
}

/// SWEET CRUSH 糖果 Logo：逐字母糖果配色 + 白描边 + 波浪起伏。
class _CandyLogo extends StatelessWidget {
  const _CandyLogo({this.letterSize = 148, this.stacked = true});

  final double letterSize;
  final bool stacked;

  static const _sweet = [
    Color(0xFFFF2D45),
    Color(0xFFFF9500),
    Color(0xFFFFCE0A),
    Color(0xFF23CE58),
    Color(0xFF1E9FFF),
  ];
  static const _crush = [
    Color(0xFFAE4BFF),
    Color(0xFFFF2D45),
    Color(0xFFFF9500),
    Color(0xFFFFCE0A),
    Color(0xFF23CE58),
  ];

  Widget _word(String word, List<Color> colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < word.length; i++)
          Transform.translate(
            offset: Offset(0, sin(i * 1.7) * letterSize * 0.055),
            child: Transform.rotate(
              angle: (i.isEven ? -1 : 1) * 0.045,
              child: _letter(word[i], colors[i % colors.length]),
            ),
          ),
      ],
    );
  }

  Widget _letter(String ch, Color color) {
    final style = TextStyle(
      fontFamily: 'Fredoka',
      fontSize: letterSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.05,
    );
    return Stack(
      children: [
        Text(
          ch,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = letterSize * 0.115
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
            shadows: [
              Shadow(
                color: const Color(0xCC2A0A4E),
                offset: Offset(0, letterSize * 0.06),
                blurRadius: 0,
              ),
              Shadow(
                color: const Color(0x73000000),
                offset: Offset(0, letterSize * 0.12),
                blurRadius: letterSize * 0.22,
              ),
            ],
          ),
        ),
        Text(ch, style: style.copyWith(color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _word('SWEET', _sweet),
          SizedBox(height: letterSize * 0.02),
          _word('CRUSH', _crush),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _word('SWEET', _sweet),
        SizedBox(width: letterSize * 0.3),
        _word('CRUSH', _crush),
      ],
    );
  }
}

/// 单颗糖果（复用游戏矢量绘制）。
class _Candy extends StatelessWidget {
  const _Candy(
    this.color, {
    this.special = SpecialType.none,
    this.size = 120,
    this.rotation = 0,
  });

  final CandyColor color;
  final SpecialType special;
  final double size;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size.square(size * 1.3),
        painter: _CandyCustomPainter(color, special),
      ),
    );
  }
}

class _CandyCustomPainter extends CustomPainter {
  _CandyCustomPainter(this.color, this.special);

  final CandyColor color;
  final SpecialType special;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    CandyPainter.paint(canvas, size.width / 1.3, color, special);
  }

  @override
  bool shouldRepaint(covariant _CandyCustomPainter old) =>
      old.color != color || old.special != special;
}

/// 冰冻糖果 / 饼干障碍展示块。
class _ObstacleTile extends StatelessWidget {
  const _ObstacleTile({required this.cookie, this.size = 150});

  final bool cookie;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size * 1.2),
      painter: _ObstaclePainter(cookie),
    );
  }
}

class _ObstaclePainter extends CustomPainter {
  _ObstaclePainter(this.cookie);

  final bool cookie;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final s = size.width / 1.2;
    if (cookie) {
      CandyPainter.paintCookie(canvas, s);
    } else {
      CandyPainter.paint(canvas, s, CandyColor.blue, SpecialType.none);
      CandyPainter.paintIce(canvas, s * 1.12);
    }
  }

  @override
  bool shouldRepaint(covariant _ObstaclePainter old) => old.cookie != cookie;
}

/// 玻璃药丸 chip（与游戏 HUD 同款质感）。
class _Chip extends StatelessWidget {
  const _Chip({this.leading, required this.label, this.fontSize = 30});

  final Widget? leading;
  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.9, vertical: fontSize * 0.42),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x59241543), Color(0x8C120A28)],
        ),
        borderRadius: BorderRadius.circular(fontSize * 1.4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: fontSize * 0.4)],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: const [
                Shadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 金色大星星行（自绘，带辉光）。
class _PromoStars extends StatelessWidget {
  const _PromoStars({this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 3.6, size * 1.5),
      painter: _StarsPainter(),
    );
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 3.6;
    for (var i = 0; i < 3; i++) {
      final big = i == 1;
      final r = unit * (big ? 0.66 : 0.5);
      final c = Offset(
        unit * (0.55 + i * 1.25),
        size.height * (big ? 0.42 : 0.58),
      );
      final star = _starPath(c, r, r * 0.5, 5, rotation: -pi / 2);
      canvas.drawPath(
        star,
        Paint()
          ..color = const Color(0x80FF9F1A)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
      );
      canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.22
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFB86A00),
      );
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFD31A));
      // 内部高光
      canvas.drawPath(
        _starPath(c.translate(0, -r * 0.08), r * 0.55, r * 0.28, 5,
            rotation: -pi / 2),
        Paint()..color = const Color(0x59FFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

Path _starPath(Offset c, double outer, double inner, int points,
    {double rotation = 0}) {
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : inner;
    final a = rotation + i * pi / points;
    final p = Offset(c.dx + cos(a) * r, c.dy + sin(a) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  return path;
}

/// 四角闪光。
void _drawSparkle(Canvas canvas, Offset c, double r, {Color color = Colors.white, double alpha = 1}) {
  final p = Path();
  for (var i = 0; i < 8; i++) {
    final radius = i.isEven ? r : r * 0.22;
    final a = -pi / 2 + i * pi / 4;
    final pt = Offset(c.dx + cos(a) * radius, c.dy + sin(a) * radius);
    if (i == 0) {
      p.moveTo(pt.dx, pt.dy);
    } else {
      p.lineTo(pt.dx, pt.dy);
    }
  }
  p.close();
  canvas.drawPath(
    p,
    Paint()
      ..color = color.withValues(alpha: 0.55 * alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
  );
  canvas.drawPath(p, Paint()..color = color.withValues(alpha: alpha));
}

// ===========================================================================
// 棋盘 Mock（1:1 复刻游戏内面板/格子/糖果渲染 + 特效）
// ===========================================================================

class _CellOverride {
  const _CellOverride({this.color, this.special, this.obstacle});

  final CandyColor? color;
  final SpecialType? special;
  final ObstacleType? obstacle;
}

class _Burst {
  const _Burst(this.row, this.col, this.color);

  final int row;
  final int col;
  final CandyColor color;
}

class _Bolt {
  const _Bolt(this.fromRow, this.fromCol, this.toRow, this.toCol);

  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
}

class _BoardMock extends StatelessWidget {
  const _BoardMock({
    required this.size,
    this.seed = 11,
    this.overrides = const {},
    this.beamRows = const [],
    this.beamCols = const [],
    this.bursts = const [],
    this.bolts = const [],
    this.swapA,
    this.swapB,
  });

  final double size;
  final int seed;
  final Map<(int, int), _CellOverride> overrides;
  final List<int> beamRows;
  final List<int> beamCols;
  final List<_Burst> bursts;
  final List<_Bolt> bolts;
  final (int, int)? swapA;
  final (int, int)? swapB;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BoardPainter(this),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.spec);

  final _BoardMock spec;

  static List<List<CandyColor>> _genGrid(int seed) {
    final rng = Random(seed);
    final g = List.generate(8, (_) => List<CandyColor?>.filled(8, null));
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final banned = <CandyColor>{};
        if (c >= 2 && g[r][c - 1] == g[r][c - 2]) banned.add(g[r][c - 1]!);
        if (r >= 2 && g[r - 1][c] == g[r - 2][c]) banned.add(g[r - 1][c]!);
        final choices =
            CandyColor.values.where((x) => !banned.contains(x)).toList();
        g[r][c] = choices[rng.nextInt(choices.length)];
      }
    }
    return [for (final row in g) [for (final c in row) c!]];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = _genGrid(spec.seed);
    final pad = size.width * 0.030;
    final boardRect = Rect.fromLTWH(
        pad, pad, size.width - pad * 2, size.height - pad * 2);
    final cell = boardRect.width / 8;
    final rrect =
        RRect.fromRectAndRadius(boardRect.inflate(pad * 0.6), Radius.circular(cell * 0.30));

    // --- 面板（与 match_game.dart 同款）---
    canvas.drawRRect(
      rrect.shift(Offset(0, size.width * 0.012)),
      Paint()
        ..color = const Color(0x59000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.016),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          boardRect.topCenter,
          boardRect.bottomCenter,
          [const Color(0xE6241543), const Color(0xE61A0F33)],
        ),
    );
    canvas.drawRRect(
      rrect.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = ui.Gradient.linear(
          boardRect.topCenter,
          boardRect.bottomCenter,
          [const Color(0x66FFFFFF), const Color(0x11FFFFFF), const Color(0x33000000)],
          const [0.0, 0.35, 1.0],
        ),
    );

    // --- 格子 ---
    final cellLight = Paint()..color = const Color(0x21FFFFFF);
    final cellDark = Paint()..color = const Color(0x0DFFFFFF);
    final cellEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x14FFFFFF);
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final rect = Rect.fromLTWH(
          boardRect.left + c * cell,
          boardRect.top + r * cell,
          cell,
          cell,
        ).deflate(cell * 0.035);
        final cellR = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.16));
        canvas.drawRRect(cellR, (r + c).isEven ? cellLight : cellDark);
        canvas.drawRRect(cellR, cellEdge);
      }
    }

    Offset center(int r, int c) => Offset(
          boardRect.left + (c + 0.5) * cell,
          boardRect.top + (r + 0.5) * cell,
        );

    // --- 糖果 ---
    final burstCells = {for (final b in spec.bursts) (b.row, b.col)};
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (burstCells.contains((r, c))) continue; // 爆裂中的格子不画糖
        final o = spec.overrides[(r, c)];
        final obstacle = o?.obstacle ?? ObstacleType.none;
        canvas.save();
        final pos = center(r, c);
        canvas.translate(pos.dx, pos.dy);
        if (obstacle == ObstacleType.cookie) {
          CandyPainter.paintCookie(canvas, cell);
        } else {
          CandyPainter.paint(
            canvas,
            cell,
            o?.color ?? grid[r][c],
            o?.special ?? SpecialType.none,
          );
          if (obstacle == ObstacleType.ice) {
            CandyPainter.paintIce(canvas, cell * 1.04);
          }
        }
        canvas.restore();
      }
    }

    // --- 特效层 ---
    for (final row in spec.beamRows) {
      _beam(canvas, boardRect, cell, horizontal: true, index: row);
    }
    for (final col in spec.beamCols) {
      _beam(canvas, boardRect, cell, horizontal: false, index: col);
    }
    for (final bolt in spec.bolts) {
      _lightning(canvas, center(bolt.fromRow, bolt.fromCol),
          center(bolt.toRow, bolt.toCol), cell);
    }
    for (final b in spec.bursts) {
      _burst(canvas, center(b.row, b.col), cell, CandyPalette.base[b.color]!);
    }
    if (spec.swapA != null && spec.swapB != null) {
      _swap(canvas, center(spec.swapA!.$1, spec.swapA!.$2),
          center(spec.swapB!.$1, spec.swapB!.$2), cell);
    }

    // 面板上零星闪光
    final rng = Random(spec.seed + 99);
    for (var i = 0; i < 5; i++) {
      _drawSparkle(
        canvas,
        Offset(
          boardRect.left + rng.nextDouble() * boardRect.width,
          boardRect.top + rng.nextDouble() * boardRect.height,
        ),
        cell * (0.10 + rng.nextDouble() * 0.10),
        alpha: 0.75,
      );
    }
  }

  void _beam(Canvas canvas, Rect board, double cell,
      {required bool horizontal, required int index}) {
    final mid = horizontal
        ? board.top + (index + 0.5) * cell
        : board.left + (index + 0.5) * cell;
    final glowRect = horizontal
        ? Rect.fromLTRB(board.left - cell * 0.2, mid - cell * 0.34,
            board.right + cell * 0.2, mid + cell * 0.34)
        : Rect.fromLTRB(mid - cell * 0.34, board.top - cell * 0.2,
            mid + cell * 0.34, board.bottom + cell * 0.2);
    final coreRect = horizontal
        ? Rect.fromLTRB(board.left, mid - cell * 0.13, board.right, mid + cell * 0.13)
        : Rect.fromLTRB(mid - cell * 0.13, board.top, mid + cell * 0.13, board.bottom);

    canvas.drawRRect(
      RRect.fromRectAndRadius(glowRect, Radius.circular(cell * 0.34)),
      Paint()
        ..color = const Color(0x8CFFD31A)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(coreRect, Radius.circular(cell * 0.13)),
      Paint()
        ..shader = ui.Gradient.linear(
          horizontal ? coreRect.topCenter : coreRect.centerLeft,
          horizontal ? coreRect.bottomCenter : coreRect.centerRight,
          [const Color(0xFFFFFFFF), const Color(0xFFFFF3C4), const Color(0xFFFFFFFF)],
          const [0.0, 0.5, 1.0],
        ),
    );
    // 光束端头闪光
    final ends = horizontal
        ? [Offset(board.left, mid), Offset(board.right, mid)]
        : [Offset(mid, board.top), Offset(mid, board.bottom)];
    for (final e in ends) {
      _drawSparkle(canvas, e, cell * 0.34, color: const Color(0xFFFFE066));
    }
  }

  void _burst(Canvas canvas, Offset c, double cell, Color color) {
    final light = shiftLightness(color, 0.22);
    // 冲击波环
    canvas.drawCircle(
      c,
      cell * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.10
        ..color = Colors.white.withValues(alpha: 0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.06),
    );
    canvas.drawCircle(
      c,
      cell * 0.40,
      Paint()
        ..color = light.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.18),
    );
    // 飞溅粒子
    final rng = Random(color.hashCode);
    for (var i = 0; i < 10; i++) {
      final a = i * pi / 5 + rng.nextDouble() * 0.5;
      final d = cell * (0.45 + rng.nextDouble() * 0.45);
      final p = Offset(c.dx + cos(a) * d, c.dy + sin(a) * d);
      final r = cell * (0.05 + rng.nextDouble() * 0.075);
      canvas.drawCircle(p, r,
          Paint()..color = (i.isEven ? color : light).withValues(alpha: 0.95));
      canvas.drawCircle(p.translate(-r * 0.3, -r * 0.3), r * 0.35,
          Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
    _drawSparkle(canvas, c, cell * 0.30);
  }

  void _lightning(Canvas canvas, Offset from, Offset to, double cell) {
    final rng = Random(from.dx.toInt() * 7 + to.dy.toInt());
    final path = Path()..moveTo(from.dx, from.dy);
    const segs = 6;
    for (var i = 1; i < segs; i++) {
      final t = i / segs;
      final base = Offset.lerp(from, to, t)!;
      final n = (to - from);
      final normal = Offset(-n.dy, n.dx) / n.distance;
      final jitter = (rng.nextDouble() - 0.5) * cell * 0.55;
      final p = base + normal * jitter;
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(to.dx, to.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.16
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x8C7CE4FF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    _drawSparkle(canvas, to, cell * 0.26, color: const Color(0xFFB3ECFF));
  }

  void _swap(Canvas canvas, Offset a, Offset b, double cell) {
    // 选中光圈
    for (final c in [a, b]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: cell * 0.96, height: cell * 0.96),
          Radius.circular(cell * 0.2),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.07
          ..color = Colors.white
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.03),
      );
    }
    // 上下两条弧形交换箭头
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final half = (b.dx - a.dx).abs() / 2;
    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.09
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFE066);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.17
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x66FFD31A)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.06);
    for (final up in [true, false]) {
      final sign = up ? -1.0 : 1.0;
      final rect = Rect.fromCenter(
          center: mid, width: half * 2.1, height: cell * 1.15);
      final start = up ? pi : 0.0;
      final path = Path()
        ..addArc(rect, start, sign > 0 ? pi * 0.8 : pi * 0.8);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, arrowPaint);
      // 箭头头部
      final tipAngle = start + pi * 0.8;
      final tip = Offset(
        mid.dx + cos(tipAngle) * rect.width / 2,
        mid.dy + sin(tipAngle) * rect.height / 2,
      );
      final dir = Offset(-sin(tipAngle), cos(tipAngle));
      final left = tip - dir * cell * 0.22 +
          Offset(dir.dy, -dir.dx) * cell * 0.14;
      final right = tip - dir * cell * 0.22 -
          Offset(dir.dy, -dir.dx) * cell * 0.14;
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(right.dx, right.dy);
      canvas.drawPath(head, glow);
      canvas.drawPath(head, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => false;
}

// ===========================================================================
// HUD / 道具栏复刻
// ===========================================================================

BoxDecoration _pillDecoration({double radius = 40}) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x40241543), Color(0x66120A28)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6)),
      ],
    );

TextStyle _hudText(double size, {FontWeight weight = FontWeight.w700, Color color = Colors.white}) =>
    TextStyle(
      fontFamily: 'Fredoka',
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

class _HudPill extends StatelessWidget {
  const _HudPill({this.icon, this.iconColor, required this.text, this.fontSize = 38});

  final IconData? icon;
  final Color? iconColor;
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.75, vertical: fontSize * 0.32),
      decoration: _pillDecoration(radius: fontSize * 1.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: fontSize * 1.05),
            SizedBox(width: fontSize * 0.3),
          ],
          Text(text, style: _hudText(fontSize)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.label, this.height = 40});

  final double progress;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0x66120A28),
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(color: Colors.white24, width: 2.4),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(height * 0.14),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8CF2A0), Color(0xFF35D461), Color(0xFF1FA84A)],
                  ),
                  borderRadius: BorderRadius.circular(height * 0.36),
                  boxShadow: const [BoxShadow(color: Color(0x8035D461), blurRadius: 14)],
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              label,
              style: _hudText(height * 0.55, weight: FontWeight.w600).copyWith(
                shadows: const [Shadow(color: Colors.black87, blurRadius: 5)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.count,
    this.diameter = 112,
  });

  final IconData icon;
  final String label;
  final Color color;
  final int count;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    final top = hsl.withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0)).toColor();
    final bottom = hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
    final rim = hsl.withLightness((hsl.lightness - 0.30).clamp(0.0, 1.0)).toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [top, color, bottom],
                  stops: const [0.0, 0.5, 1.0],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2.6),
                boxShadow: [
                  BoxShadow(color: rim, offset: Offset(0, diameter * 0.065)),
                  BoxShadow(
                    color: const Color(0x59000000),
                    blurRadius: diameter * 0.13,
                    offset: Offset(0, diameter * 0.08),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: diameter * 0.1,
                    child: Container(
                      width: diameter * 0.6,
                      height: diameter * 0.26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(diameter * 0.16),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    color: Colors.white,
                    size: diameter * 0.5,
                    shadows: const [
                      Shadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 5),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: -diameter * 0.06,
              top: -diameter * 0.06,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: diameter * 0.1, vertical: diameter * 0.035),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(diameter * 0.16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x4D000000), blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Text('$count',
                    style: _hudText(diameter * 0.21, color: rim)),
              ),
            ),
          ],
        ),
        SizedBox(height: diameter * 0.09),
        Text(label,
            style: _hudText(diameter * 0.21,
                weight: FontWeight.w600, color: Colors.white70)),
      ],
    );
  }
}

/// 飘字（金色描边）。
class _FloatText extends StatelessWidget {
  const _FloatText(this.text, {this.fontSize = 58, this.rotation = -0.06});

  final String text;
  final double fontSize;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: _StrokeText(
        text,
        fontSize: fontSize,
        fill: const Color(0xFFFFD31A),
        stroke: const Color(0xFF7A3E00),
        strokeWidth: fontSize * 0.16,
      ),
    );
  }
}

// ===========================================================================
// 竖图 1：Hero
// ===========================================================================

class _HeroPortrait extends StatelessWidget {
  const _HeroPortrait();

  @override
  Widget build(BuildContext context) {
    return _PromoBackground(
      seed: 5,
      child: Column(
        children: [
          const SizedBox(height: 150),
          const _CandyLogo(letterSize: 168),
          const SizedBox(height: 34),
          const _StrokeText(
            'The sweetest match-3 adventure!',
            fontSize: 46,
            weight: FontWeight.w600,
          ),
          const Spacer(),
          // 中央糖果爆发
          SizedBox(
            height: 800,
            width: 1080,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: const Size(1080, 800),
                  painter: _HeroBurstPainter(),
                ),
                const _Candy(CandyColor.red,
                    special: SpecialType.colorBomb, size: 330),
                ..._orbit(),
              ],
            ),
          ),
          const Spacer(),
          const _PromoStars(size: 74),
          const SizedBox(height: 44),
          const Wrap(
            spacing: 26,
            alignment: WrapAlignment.center,
            children: [
              _Chip(label: '6 glossy candies'),
              _Chip(label: 'Explosive specials'),
              _Chip(label: 'Play offline'),
            ],
          ),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  static List<Widget> _orbit() {
    const items = [
      (CandyColor.red, SpecialType.none, 0.0, 150.0, 0.35),
      (CandyColor.blue, SpecialType.none, 55.0, 135.0, -0.2),
      (CandyColor.green, SpecialType.none, 115.0, 155.0, 0.25),
      (CandyColor.yellow, SpecialType.none, 175.0, 140.0, -0.3),
      (CandyColor.orange, SpecialType.stripedH, 235.0, 150.0, 0.18),
      (CandyColor.purple, SpecialType.none, 295.0, 145.0, -0.25),
      (CandyColor.green, SpecialType.wrapped, 330.0, 125.0, 0.3),
      (CandyColor.blue, SpecialType.stripedV, 145.0, 115.0, -0.15),
    ];
    return [
      for (final (color, special, deg, size, rot) in items)
        Transform.translate(
          offset: Offset(
            cos(deg * pi / 180) * 335,
            sin(deg * pi / 180) * 285,
          ),
          child: _Candy(color, special: special, size: size, rotation: rot),
        ),
    ];
  }
}

class _HeroBurstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    // 中央辉光
    canvas.drawCircle(
      c,
      330,
      Paint()
        ..shader = ui.Gradient.radial(c, 330, [
          const Color(0x59FF9FF3),
          const Color(0x26AE4BFF),
          const Color(0x00AE4BFF),
        ], const [
          0.0,
          0.55,
          1.0,
        ]),
    );
    // 放射光线
    final rng = Random(3);
    for (var i = 0; i < 14; i++) {
      final a = i * pi / 7 + 0.12;
      final len = 300 + rng.nextDouble() * 110;
      final p = Paint()
        ..shader = ui.Gradient.linear(
          c + Offset(cos(a), sin(a)) * 150,
          c + Offset(cos(a), sin(a)) * len,
          [const Color(0x40FFE9A6), const Color(0x00FFE9A6)],
        )
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * 150,
          c + Offset(cos(a), sin(a)) * len, p);
    }
    // 装饰环
    for (final (r, alpha) in [(255.0, 0.18), (300.0, 0.10)]) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 2.3, height: r * 1.95),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: alpha),
      );
    }
    // 闪光
    final sparkRng = Random(8);
    for (var i = 0; i < 9; i++) {
      final a = sparkRng.nextDouble() * 2 * pi;
      final d = 190 + sparkRng.nextDouble() * 210;
      _drawSparkle(
        canvas,
        c + Offset(cos(a) * d * 1.1, sin(a) * d * 0.85),
        9 + sparkRng.nextDouble() * 16,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ===========================================================================
// 竖图 2：对局画面
// ===========================================================================

class _GameplayPortrait extends StatelessWidget {
  const _GameplayPortrait();

  @override
  Widget build(BuildContext context) {
    return _PromoBackground(
      seed: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 92),
            const _StrokeText('SWAP, MATCH & POP!', fontSize: 88),
            const SizedBox(height: 20),
            const _StrokeText(
              'Set off delicious chain reactions',
              fontSize: 40,
              weight: FontWeight.w600,
              fill: Color(0xFFFFE9A6),
            ),
            const SizedBox(height: 56),
            // HUD
            Row(
              children: [
                const _HudPill(
                  icon: Icons.swipe_rounded,
                  iconColor: Color(0xFF7CE4FF),
                  text: '23',
                ),
                const Spacer(),
                const _HudPill(text: 'Level 7', fontSize: 34),
                const Spacer(),
                const _HudPill(
                  icon: Icons.stars_rounded,
                  iconColor: Color(0xFFFFD31A),
                  text: '12,480',
                ),
              ],
            ),
            const SizedBox(height: 26),
            const _ProgressBar(progress: 0.66, label: 'Goal: 18,000'),
            const SizedBox(height: 40),
            // 棋盘 + 飘字
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const _BoardMock(
                  size: 968,
                  seed: 21,
                  overrides: {
                    (4, 3): _CellOverride(
                        color: CandyColor.orange, special: SpecialType.stripedH),
                    (1, 6): _CellOverride(
                        color: CandyColor.purple, special: SpecialType.wrapped),
                    (0, 0): _CellOverride(obstacle: ObstacleType.ice),
                    (7, 7): _CellOverride(obstacle: ObstacleType.cookie),
                  },
                  beamRows: [4],
                  bursts: [_Burst(2, 1, CandyColor.red)],
                  swapA: (6, 2),
                  swapB: (6, 3),
                ),
                const Positioned(
                  top: 150,
                  left: 90,
                  child: _FloatText('Sweet! +750', fontSize: 62),
                ),
              ],
            ),
            const SizedBox(height: 52),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BoosterButton(
                  icon: Icons.gavel_rounded,
                  label: 'Hammer',
                  color: Color(0xFFFFA726),
                  count: 3,
                ),
                _BoosterButton(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Bomb',
                  color: Color(0xFFFF5252),
                  count: 2,
                ),
                _BoosterButton(
                  icon: Icons.cached_rounded,
                  label: 'Shuffle',
                  color: Color(0xFF40C4FF),
                  count: 1,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 竖图 3：特殊糖果
// ===========================================================================

class _SpecialsPortrait extends StatelessWidget {
  const _SpecialsPortrait();

  @override
  Widget build(BuildContext context) {
    return _PromoBackground(
      seed: 33,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 100),
            const _StrokeText('MIGHTY SPECIALS', fontSize: 92),
            const SizedBox(height: 20),
            const _StrokeText(
              'Match 4 or more to craft them',
              fontSize: 40,
              weight: FontWeight.w600,
              fill: Color(0xFFFFE9A6),
            ),
            const SizedBox(height: 70),
            _card(
              visual: const _Candy(CandyColor.orange,
                  special: SpecialType.stripedH, size: 200),
              beam: true,
              title: 'Striped Candy',
              titleColor: const Color(0xFFFFB347),
              desc: 'Blasts the entire row or column',
            ),
            const SizedBox(height: 44),
            _card(
              visual: const _Candy(CandyColor.red,
                  special: SpecialType.wrapped, size: 190),
              ring: true,
              title: 'Wrapped Candy',
              titleColor: const Color(0xFFFF6E7E),
              desc: 'Explodes twice in a 3x3 blast',
            ),
            const SizedBox(height: 44),
            _card(
              visual: const _Candy(CandyColor.red,
                  special: SpecialType.colorBomb, size: 200),
              sparkles: true,
              title: 'Color Bomb',
              titleColor: const Color(0xFFCE8CFF),
              desc: 'Clears every candy of one color',
            ),
            const SizedBox(height: 80),
            const Center(
              child: _Chip(
                leading: _Candy(CandyColor.red,
                    special: SpecialType.colorBomb, size: 52),
                label: 'Combine two specials for MEGA effects!',
                fontSize: 36,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required Widget visual,
    required String title,
    required Color titleColor,
    required String desc,
    bool beam = false,
    bool ring = false,
    bool sparkles = false,
  }) {
    return Container(
      height: 330,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66241543), Color(0x8C120A28)],
        ),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 280,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(280, 300),
                  painter: _SpecialFxPainter(
                      beam: beam, ring: ring, sparkles: sparkles),
                ),
                visual,
              ],
            ),
          ),
          const SizedBox(width: 36),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StrokeText(
                  title,
                  fontSize: 58,
                  fill: titleColor,
                  align: TextAlign.left,
                ),
                const SizedBox(height: 16),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 37,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialFxPainter extends CustomPainter {
  _SpecialFxPainter({this.beam = false, this.ring = false, this.sparkles = false});

  final bool beam;
  final bool ring;
  final bool sparkles;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    if (beam) {
      final rect = Rect.fromCenter(center: c, width: size.width * 1.0, height: 44);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(16), const Radius.circular(40)),
        Paint()
          ..color = const Color(0x66FFD31A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(22)),
        Paint()..color = const Color(0xE6FFF6D6),
      );
      _drawSparkle(canvas, Offset(rect.left, c.dy), 24, color: const Color(0xFFFFE066));
      _drawSparkle(canvas, Offset(rect.right, c.dy), 24, color: const Color(0xFFFFE066));
    }
    if (ring) {
      canvas.drawCircle(
        c,
        118,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = const Color(0xCCFFFFFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        c,
        142,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = const Color(0x59FF6E7E)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      final rng = Random(4);
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4 + 0.2;
        final d = 120 + rng.nextDouble() * 25;
        canvas.drawCircle(
          c + Offset(cos(a) * d, sin(a) * d),
          7 + rng.nextDouble() * 8,
          Paint()..color = const Color(0xFFFF6E7E),
        );
      }
    }
    if (sparkles) {
      canvas.drawCircle(
        c,
        130,
        Paint()
          ..shader = ui.Gradient.radial(c, 130, [
            const Color(0x40B45CFF),
            const Color(0x00B45CFF),
          ]),
      );
      final rng = Random(6);
      for (var i = 0; i < 7; i++) {
        final a = rng.nextDouble() * 2 * pi;
        final d = 105 + rng.nextDouble() * 32;
        _drawSparkle(canvas, c + Offset(cos(a) * d, sin(a) * d),
            8 + rng.nextDouble() * 12,
            color: const Color(0xFFE9CCFF));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ===========================================================================
// 竖图 4：游戏模式与障碍
// ===========================================================================

class _ModesPortrait extends StatelessWidget {
  const _ModesPortrait();

  @override
  Widget build(BuildContext context) {
    return _PromoBackground(
      seed: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 100),
            const _StrokeText('3 SWEET GAME MODES', fontSize: 84),
            const SizedBox(height: 20),
            const _StrokeText(
              '35+ handcrafted levels to master',
              fontSize: 40,
              weight: FontWeight.w600,
              fill: Color(0xFFFFE9A6),
            ),
            const SizedBox(height: 64),
            _modeCard(
              visual: const _TargetVisual(),
              title: 'Classic',
              titleColor: const Color(0xFF7CE4FF),
              desc: 'Hit the target score in limited moves',
            ),
            const SizedBox(height: 38),
            _modeCard(
              visual: const _CollectVisual(),
              title: 'Collect',
              titleColor: const Color(0xFF8CF2A0),
              desc: 'Gather every candy on the list',
            ),
            const SizedBox(height: 38),
            _modeCard(
              visual: const _TimerVisual(),
              title: 'Timed',
              titleColor: const Color(0xFFFFB347),
              desc: '60 seconds of pure score rush',
            ),
            const SizedBox(height: 62),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _obstacleChip(const _ObstacleTile(cookie: false, size: 130),
                    'Break the ice!'),
                _obstacleChip(const _ObstacleTile(cookie: true, size: 130),
                    'Crush the cookies!'),
              ],
            ),
            const Spacer(),
            const Center(child: _PromoStars(size: 66)),
            const SizedBox(height: 24),
            const Center(
              child: _StrokeText(
                'Earn all three stars!',
                fontSize: 44,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  static Widget _modeCard({
    required Widget visual,
    required String title,
    required Color titleColor,
    required String desc,
  }) {
    return Container(
      height: 264,
      padding: const EdgeInsets.symmetric(horizontal: 44),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66241543), Color(0x8C120A28)],
        ),
        borderRadius: BorderRadius.circular(44),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 9)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 210, height: 220, child: Center(child: visual)),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StrokeText(title,
                    fontSize: 56, fill: titleColor, align: TextAlign.left),
                const SizedBox(height: 12),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 35,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _obstacleChip(Widget visual, String label) {
    return Column(
      children: [
        visual,
        const SizedBox(height: 14),
        _StrokeText(label, fontSize: 38, weight: FontWeight.w600),
      ],
    );
  }
}

/// 经典模式：靶心 + 糖果。
class _TargetVisual extends StatelessWidget {
  const _TargetVisual();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(190),
      painter: _TargetPainter(),
    );
  }
}

class _TargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (final (r, color) in [
      (88.0, const Color(0xFF7CE4FF)),
      (66.0, Colors.white),
      (44.0, const Color(0xFF7CE4FF)),
    ]) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15
          ..color = color,
      );
    }
    canvas.translate(c.dx, c.dy);
    CandyPainter.paint(canvas, 62, CandyColor.blue, SpecialType.none);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// 收集模式：糖果 + 计数 chips。
class _CollectVisual extends StatelessWidget {
  const _CollectVisual();

  @override
  Widget build(BuildContext context) {
    Widget goal(CandyColor color, String count) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x66120A28),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF6FE08A), width: 2.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Candy(color, size: 44),
              const SizedBox(width: 8),
              Text(count, style: _hudText(28)),
            ],
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        goal(CandyColor.red, '0/20'),
        const SizedBox(height: 12),
        goal(CandyColor.yellow, '4/15'),
      ],
    );
  }
}

/// 限时模式：表盘。
class _TimerVisual extends StatelessWidget {
  const _TimerVisual();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(190),
      painter: _TimerPainter(),
    );
  }
}

class _TimerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 6);
    const r = 82.0;
    // 提手
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, -r - 14), width: 34, height: 20),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFFFB347),
    );
    // 表盘
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c.translate(-20, -24), r * 2.2, [
          const Color(0xFFFFD98F),
          const Color(0xFFFFB347),
          const Color(0xFFDD8A1D),
        ], const [
          0.0,
          0.55,
          1.0,
        ]),
    );
    canvas.drawCircle(c, r * 0.78, Paint()..color = const Color(0xFFFFF7E8));
    // 弧形进度
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.62),
      -pi / 2,
      pi * 1.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFF5252),
    );
    // 指针
    canvas.drawLine(
      c,
      c + Offset(cos(-pi / 2 + pi * 1.4) * r * 0.5, sin(-pi / 2 + pi * 1.4) * r * 0.5),
      Paint()
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF5A3319),
    );
    canvas.drawCircle(c, 10, Paint()..color = const Color(0xFF5A3319));
    // 高光
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.9),
      pi * 1.15,
      pi * 0.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x8CFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ===========================================================================
// 横图 1：Hero
// ===========================================================================

class _HeroLandscape extends StatelessWidget {
  const _HeroLandscape();

  @override
  Widget build(BuildContext context) {
    return _PromoBackground(
      seed: 55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 90),
        child: Row(
          children: [
            // 左侧文案
            SizedBox(
              width: 830,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CandyLogo(letterSize: 132),
                  const SizedBox(height: 30),
                  const _StrokeText(
                    'The sweetest match-3 adventure!',
                    fontSize: 42,
                    weight: FontWeight.w600,
                    align: TextAlign.left,
                  ),
                  const SizedBox(height: 44),
                  _bullet(CandyColor.red, 'Explosive special candies'),
                  _bullet(CandyColor.blue, 'Dazzling chain combos'),
                  _bullet(CandyColor.green, '3 modes, 35+ sweet levels'),
                  _bullet(CandyColor.yellow, 'Play offline, anywhere'),
                  const SizedBox(height: 40),
                  const _PromoStars(size: 60),
                ],
              ),
            ),
            const Spacer(),
            // 右侧倾斜棋盘
            SizedBox(
              width: 900,
              height: 1080,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Transform.rotate(
                    angle: -0.055,
                    child: const _BoardMock(
                      size: 830,
                      seed: 31,
                      overrides: {
                        (2, 5): _CellOverride(
                            color: CandyColor.green,
                            special: SpecialType.wrapped),
                        (5, 2): _CellOverride(
                            color: CandyColor.blue,
                            special: SpecialType.stripedV),
                        (0, 1): _CellOverride(obstacle: ObstacleType.ice),
                      },
                      beamCols: [2],
                      bursts: [_Burst(4, 6, CandyColor.purple)],
                    ),
                  ),
                  const Positioned(
                    left: -60,
                    bottom: 130,
                    child: _Candy(CandyColor.red, size: 190, rotation: 0.4),
                  ),
                  const Positioned(
                    right: -40,
                    top: 110,
                    child: _Candy(CandyColor.red,
                        special: SpecialType.colorBomb, size: 210),
                  ),
                  const Positioned(
                    right: 30,
                    bottom: 80,
                    child:
                        _Candy(CandyColor.yellow, size: 150, rotation: -0.35),
                  ),
                  const Positioned(
                    top: 130,
                    left: 40,
                    child: _FloatText('Divine!', fontSize: 68),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bullet(CandyColor color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        children: [
          _Candy(color, size: 52),
          const SizedBox(width: 20),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(color: Color(0x73000000), offset: Offset(0, 3), blurRadius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 横图 2：连锁反应
// ===========================================================================

class _CombosLandscape extends StatelessWidget {
  const _CombosLandscape();

  @override
  Widget build(BuildContext context) {
    return _PromoBackground(
      seed: 66,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 中央棋盘（略微放大裁切以突出特效）
          Positioned(
            top: 270,
            child: _BoardMock(
              size: 760,
              seed: 41,
              overrides: const {
                (3, 4): _CellOverride(
                    color: CandyColor.yellow, special: SpecialType.stripedH),
                (6, 1): _CellOverride(
                    color: CandyColor.red, special: SpecialType.colorBomb),
                (2, 2): _CellOverride(
                    color: CandyColor.purple, special: SpecialType.wrapped),
              },
              beamRows: const [3],
              beamCols: const [4],
              bolts: const [
                _Bolt(6, 1, 1, 6),
                _Bolt(6, 1, 0, 3),
                _Bolt(6, 1, 4, 7),
              ],
              bursts: const [
                _Burst(1, 6, CandyColor.blue),
                _Burst(0, 3, CandyColor.green),
                _Burst(4, 7, CandyColor.yellow),
              ],
            ),
          ),
          // 顶部标题
          const Positioned(
            top: 78,
            child: Column(
              children: [
                _StrokeText('EPIC CHAIN REACTIONS', fontSize: 92),
                SizedBox(height: 14),
                _StrokeText(
                  'Beams, blasts and lightning fill the board',
                  fontSize: 40,
                  weight: FontWeight.w600,
                  fill: Color(0xFFFFE9A6),
                ),
              ],
            ),
          ),
          // 两侧巨型特殊糖
          const Positioned(
            left: 120,
            top: 430,
            child: _Candy(CandyColor.purple,
                special: SpecialType.wrapped, size: 300, rotation: -0.12),
          ),
          const Positioned(
            left: 90,
            bottom: 90,
            child: _Candy(CandyColor.orange,
                special: SpecialType.stripedH, size: 210, rotation: 0.25),
          ),
          const Positioned(
            right: 110,
            top: 400,
            child: _Candy(CandyColor.red,
                special: SpecialType.colorBomb, size: 330),
          ),
          const Positioned(
            right: 160,
            bottom: 80,
            child: _Candy(CandyColor.green, size: 170, rotation: -0.3),
          ),
          const Positioned(
            right: 330,
            top: 300,
            child: _FloatText('Sweet!', fontSize: 74, rotation: 0.08),
          ),
          const Positioned(
            left: 330,
            bottom: 190,
            child: _FloatText('Divine!', fontSize: 74, rotation: -0.1),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Feature Graphic 1024x500
// ===========================================================================

class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic();

  @override
  Widget build(BuildContext context) {
    return _PromoBackground(
      seed: 77,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _CandyLogo(letterSize: 100),
                SizedBox(height: 16),
                _StrokeText(
                  'The sweetest match-3 adventure!',
                  fontSize: 27,
                  weight: FontWeight.w600,
                ),
              ],
            ),
          ),
          // 右侧糖果簇
          const Positioned(
            right: 118,
            top: 96,
            child:
                _Candy(CandyColor.red, special: SpecialType.colorBomb, size: 220),
          ),
          const Positioned(
            right: 300,
            top: 40,
            child: _Candy(CandyColor.yellow, size: 110, rotation: 0.3),
          ),
          const Positioned(
            right: 280,
            bottom: 30,
            child: _Candy(CandyColor.green,
                special: SpecialType.wrapped, size: 110, rotation: -0.2),
          ),
          const Positioned(
            right: 60,
            bottom: 40,
            child: _Candy(CandyColor.orange,
                special: SpecialType.stripedH, size: 120, rotation: 0.2),
          ),
          const Positioned(
            right: 36,
            top: 42,
            child: _Candy(CandyColor.red, size: 96, rotation: -0.4),
          ),
          CustomPaint(
            size: const Size(1024, 500),
            painter: _FeatureSparklePainter(),
          ),
        ],
      ),
    );
  }
}

class _FeatureSparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(9);
    for (var i = 0; i < 8; i++) {
      _drawSparkle(
        canvas,
        Offset(size.width * (0.55 + rng.nextDouble() * 0.42),
            size.height * rng.nextDouble()),
        5 + rng.nextDouble() * 11,
        alpha: 0.9,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ===========================================================================
// 应用图标 512x512：与 App 启动图标（test/icon_gen_test.dart）同一构图。
// 区别仅在于输出全出血方形——Play 商店会自动叠加 ~20% 圆角遮罩，
// 不能像旧版 launcher 图标那样预先烘焙圆角。
// ===========================================================================

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(512),
      painter: _AppIconPainter(),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;

    // 紫色渐变底（与 icon_gen_test.dart 一致）
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          const [Color(0xFF3B1866), Color(0xFF5B2C96), Color(0xFF3A3D8F)],
          const [0.0, 0.55, 1.0],
        ),
    );
    // 顶部径向柔光
    canvas.drawCircle(
      Offset(s * 0.30, s * 0.12),
      s * 0.55,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(s * 0.30, s * 0.12),
          s * 0.55,
          const [Color(0x40FF9FF3), Color(0x00FF9FF3)],
        ),
    );

    canvas.save();
    canvas.translate(s / 2, s / 2);

    // 主体：包装糖，微微旋转更俏皮
    canvas.save();
    canvas.rotate(-pi / 14);
    CandyPainter.paint(canvas, s * 0.56, CandyColor.red, SpecialType.wrapped);
    canvas.restore();

    // 点缀小糖果
    canvas.save();
    canvas.translate(-s * 0.345, s * 0.315);
    canvas.rotate(pi / 8);
    CandyPainter.paint(canvas, s * 0.16, CandyColor.yellow, SpecialType.none);
    canvas.restore();

    canvas.save();
    canvas.translate(s * 0.345, -s * 0.30);
    canvas.rotate(-pi / 10);
    CandyPainter.paint(canvas, s * 0.14, CandyColor.blue, SpecialType.none);
    canvas.restore();

    // 星光点缀
    _iconSparkle(canvas, Offset(-s * 0.27, -s * 0.30), s * 0.045);
    _iconSparkle(canvas, Offset(s * 0.33, s * 0.20), s * 0.03);
    _iconSparkle(canvas, Offset(s * 0.05, s * 0.36), s * 0.022);

    canvas.restore();
  }

  /// 与 icon_gen_test.dart 相同的四角星。
  static void _iconSparkle(Canvas canvas, Offset at, double r) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final d = i.isEven ? r : r * 0.36;
      final p = at + Offset(cos(a) * d, sin(a) * d);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xE6FFFFFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
