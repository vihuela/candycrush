import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

import 'candy_spec.dart';

/// 矢量绘制精致糖果。
///
/// 质感分 6 层：投影 → 渐变主体 → 底部反弹光 → 内缘环境光遮蔽 →
/// 顶部边缘亮线 → 大高光 + 热点高光，模拟糖衣的通透感。
class CandyPainter {
  /// 在以 (0,0) 为中心、格子边长 [size] 的区域内绘制糖果。
  static void paint(
    Canvas canvas,
    double size,
    CandyColor color,
    SpecialType special,
  ) {
    final r = size * 0.42;
    if (special == SpecialType.colorBomb) {
      _paintColorBomb(canvas, r);
      return;
    }
    if (special == SpecialType.wrapped) {
      _paintWrapped(canvas, r, color);
      return;
    }

    final path = shapePath(color, r);
    _drawBody(canvas, path, r, color);

    if (special == SpecialType.stripedH || special == SpecialType.stripedV) {
      _paintStripes(canvas, path, r, special == SpecialType.stripedH);
    }
  }

  /// 每种颜色一个专属形状，颜色+形状双重区分。
  static Path shapePath(CandyColor color, double r) {
    switch (color) {
      case CandyColor.red:
        // 糖豆（椭圆）
        return Path()
          ..addOval(Rect.fromCenter(
              center: Offset.zero, width: r * 2.14, height: r * 1.74));
      case CandyColor.orange:
        // 圆角六边形棱糖
        return _roundedPoly(
          [
            for (var i = 0; i < 6; i++)
              Offset(
                cos(i * pi / 3 - pi / 6) * r * 1.08,
                sin(i * pi / 3 - pi / 6) * r * 1.08,
              ),
          ],
          r * 0.30,
        );
      case CandyColor.yellow:
        // 水滴糖
        return _dropPath(r);
      case CandyColor.green:
        // 圆角方块软糖
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: r * 1.86, height: r * 1.86),
            Radius.circular(r * 0.62),
          ));
      case CandyColor.blue:
        // 圆球硬糖
        return Path()
          ..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 1.02));
      case CandyColor.purple:
        // 三联浆果
        final p = Path();
        for (var i = 0; i < 3; i++) {
          final a = -pi / 2 + i * 2 * pi / 3;
          p.addOval(Rect.fromCircle(
            center: Offset(cos(a) * r * 0.44, sin(a) * r * 0.44),
            radius: r * 0.64,
          ));
        }
        return p;
    }
  }

  static Path _dropPath(double r) {
    return Path()
      ..moveTo(0, -r * 1.16)
      ..cubicTo(r * 0.30, -r * 0.86, r * 0.80, -r * 0.42, r * 0.80, r * 0.22)
      ..arcToPoint(
        Offset(-r * 0.80, r * 0.22),
        radius: Radius.circular(r * 0.80),
        clockwise: true,
        largeArc: true,
      )
      ..cubicTo(-r * 0.80, -r * 0.42, -r * 0.30, -r * 0.86, 0, -r * 1.16)
      ..close();
  }

  /// 圆角多边形。
  static Path _roundedPoly(List<Offset> pts, double radius) {
    final path = Path();
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final v = pts[i];
      final next = pts[(i + 1) % n];
      final inDir = (v - prev) / (v - prev).distance;
      final outDir = (next - v) / (next - v).distance;
      final entry = v - inDir * radius;
      final exit = v + outDir * radius;
      if (i == 0) {
        path.moveTo(entry.dx, entry.dy);
      } else {
        path.lineTo(entry.dx, entry.dy);
      }
      path.quadraticBezierTo(v.dx, v.dy, exit.dx, exit.dy);
    }
    path.close();
    return path;
  }

  // ---------- 质感渲染 ----------

  static void _drawBody(Canvas canvas, Path path, double r, CandyColor c) {
    final base = CandyPalette.base[c]!;
    final light = shiftLightness(base, 0.32);
    final lighter = shiftLightness(base, 0.18);
    final dark1 = shiftLightness(base, -0.12);
    final dark2 = shiftLightness(base, -0.28);

    // 1. 柔和投影
    canvas.drawPath(
      path.shift(Offset(0, r * 0.13)),
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );

    // 2. 渐变主体
    canvas.drawPath(
      path,
      Paint()
        ..shader = Gradient.radial(
          Offset(-r * 0.32, -r * 0.40),
          r * 2.35,
          [light, lighter, base, dark1, dark2],
          const [0.0, 0.22, 0.50, 0.78, 1.0],
        ),
    );

    canvas.save();
    canvas.clipPath(path);

    // 3. 底部反弹光（糖果的通透感）
    final bounce = Rect.fromCenter(
        center: Offset(0, r * 0.76), width: r * 1.9, height: r * 1.1);
    canvas.drawOval(
      bounce,
      Paint()
        ..shader = Gradient.radial(
          bounce.center,
          bounce.width / 2,
          [
            shiftLightness(base, 0.24).withValues(alpha: 0.55),
            shiftLightness(base, 0.24).withValues(alpha: 0.0),
          ],
        ),
    );

    // 4. 内缘阴影（贴边一圈暗色，增强体积）
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.20
        ..color = dark2.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.06),
    );

    // 5. 顶部边缘亮线
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09
        ..shader = Gradient.linear(
          Offset(0, -r * 1.1),
          Offset(0, r * 0.5),
          [
            const Color(0xB3FFFFFF),
            const Color(0x00FFFFFF),
          ],
        ),
    );

    // 6. 大高光（顶部弧形柔光）
    final gloss = Rect.fromCenter(
      center: Offset(-r * 0.10, -r * 0.55),
      width: r * 1.30,
      height: r * 0.72,
    );
    canvas.drawOval(
      gloss,
      Paint()
        ..shader = Gradient.linear(
          gloss.topCenter,
          gloss.bottomCenter,
          [
            const Color(0xB8FFFFFF),
            const Color(0x08FFFFFF),
          ],
        ),
    );

    // 7. 热点高光（小而亮）
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.40, -r * 0.48),
        width: r * 0.40,
        height: r * 0.26,
      ),
      Paint()
        ..color = const Color(0xF2FFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.03),
    );

    canvas.restore();
  }

  // ---------- 特殊糖 ----------

  static void _paintStripes(
      Canvas canvas, Path body, double r, bool horizontal) {
    canvas.save();
    canvas.clipPath(body);
    for (var i = -1; i <= 1; i++) {
      final off = i * r * 0.54;
      final rect = horizontal
          ? Rect.fromCenter(
              center: Offset(0, off), width: r * 2.6, height: r * 0.26)
          : Rect.fromCenter(
              center: Offset(off, 0), width: r * 0.26, height: r * 2.6);
      // 条纹下暗边（浮雕感）
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.shift(Offset(0, r * 0.04)), Radius.circular(r * 0.13)),
        Paint()..color = const Color(0x33000000),
      );
      // 白色条纹本体（带渐变）
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r * 0.13)),
        Paint()
          ..shader = Gradient.linear(
            horizontal ? rect.topCenter : rect.centerLeft,
            horizontal ? rect.bottomCenter : rect.centerRight,
            [const Color(0xFFFFFFFF), const Color(0xCCE8F4FF)],
          ),
      );
    }
    canvas.restore();
  }

  static void _paintWrapped(Canvas canvas, double r, CandyColor c) {
    final base = CandyPalette.base[c]!;
    final dark = shiftLightness(base, -0.22);

    // 糖纸两端（渐变褶皱）
    for (final sign in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(sign * r * 0.70, -r * 0.10)
        ..lineTo(sign * r * 1.30, -r * 0.55)
        ..quadraticBezierTo(
            sign * r * 1.52, 0, sign * r * 1.30, r * 0.55)
        ..lineTo(sign * r * 0.70, r * 0.10)
        ..close();
      canvas.drawPath(
        ear,
        Paint()
          ..shader = Gradient.linear(
            Offset(sign * r * 0.7, 0),
            Offset(sign * r * 1.5, 0),
            [dark, shiftLightness(base, -0.05)],
          ),
      );
      // 褶皱线
      canvas.drawLine(
        Offset(sign * r * 0.72, 0),
        Offset(sign * r * 1.34, -r * 0.40),
        Paint()
          ..color = const Color(0x55FFFFFF)
          ..strokeWidth = r * 0.05,
      );
    }

    // 主体球
    final body = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.94));
    _drawBody(canvas, body, r * 0.94, c);

    // 螺旋纹
    canvas.save();
    canvas.clipPath(body);
    final swirl = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x7DFFFFFF);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.58),
        0.5, 2.1, false, swirl);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.32),
        2.9, 2.1, false, swirl);
    canvas.restore();
  }

  static void _paintColorBomb(Canvas canvas, double r) {
    // 外圈魔法光晕
    canvas.drawCircle(
      Offset.zero,
      r * 1.22,
      Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          r * 1.25,
          [
            const Color(0x00B45CFF),
            const Color(0x33B45CFF),
            const Color(0x00B45CFF),
          ],
          const [0.6, 0.85, 1.0],
        ),
    );

    final body = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 1.02));
    // 投影
    canvas.drawPath(
      body.shift(Offset(0, r * 0.12)),
      Paint()
        ..color = const Color(0x45000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );
    // 巧克力球体
    canvas.drawPath(
      body,
      Paint()
        ..shader = Gradient.radial(
          Offset(-r * 0.35, -r * 0.42),
          r * 2.3,
          [
            const Color(0xFF7A4A2B),
            const Color(0xFF5A3319),
            const Color(0xFF3A1F0C),
            const Color(0xFF241205),
          ],
          const [0.0, 0.45, 0.8, 1.0],
        ),
    );

    canvas.save();
    canvas.clipPath(body);
    // 彩色糖粒（带各自小高光）
    final rng = Random(7);
    for (var i = 0; i < 15; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final d = sqrt(rng.nextDouble()) * r * 0.80;
      final center = Offset(cos(a) * d, sin(a) * d);
      final dotColor =
          CandyPalette.base[CandyColor.values[i % CandyColor.values.length]]!;
      canvas.drawCircle(
        center.translate(0, r * 0.02),
        r * 0.115,
        Paint()..color = const Color(0x44000000),
      );
      canvas.drawCircle(center, r * 0.11, Paint()..color = dotColor);
      canvas.drawCircle(
        center.translate(-r * 0.03, -r * 0.03),
        r * 0.035,
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }
    // 大高光
    final gloss = Rect.fromCenter(
      center: Offset(-r * 0.12, -r * 0.55),
      width: r * 1.25,
      height: r * 0.68,
    );
    canvas.drawOval(
      gloss,
      Paint()
        ..shader = Gradient.linear(
          gloss.topCenter,
          gloss.bottomCenter,
          [const Color(0x99FFFFFF), const Color(0x05FFFFFF)],
        ),
    );
    canvas.restore();
  }
}

/// 让颜色变亮/变暗的小工具。
Color shiftLightness(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}
