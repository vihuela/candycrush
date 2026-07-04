import 'dart:math';
import 'dart:ui' show Gradient;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' hide Gradient;

import 'candy_painter.dart';
import 'candy_spec.dart';

final _rng = Random();

/// 糖果爆裂粒子：碎片 + 星光。
ParticleSystemComponent burstParticles(
  Vector2 at,
  CandyColor color,
  double cellSize, {
  double intensity = 1,
}) {
  final base = CandyPalette.base[color]!;
  final count = (10 * intensity).round();
  return ParticleSystemComponent(
    position: at,
    priority: 60,
    particle: Particle.generate(
      count: count,
      lifespan: 0.55,
      generator: (i) {
        final angle = _rng.nextDouble() * 2 * pi;
        final speed = cellSize * (3 + _rng.nextDouble() * 6) * intensity;
        final vel = Vector2(cos(angle), sin(angle)) * speed;
        final radius = cellSize * (0.05 + _rng.nextDouble() * 0.09);
        final c = [
          base,
          shiftLightness(base, 0.2),
          shiftLightness(base, -0.15),
          const Color(0xFFFFFFFF),
        ][i % 4];
        return AcceleratedParticle(
          speed: vel,
          acceleration: Vector2(0, cellSize * 18),
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final t = particle.progress;
              final paint = Paint()
                ..color = c.withValues(alpha: (1 - t).clamp(0, 1));
              if (i % 3 == 0) {
                // 四角星
                _drawStar(canvas, radius * 1.6 * (1 - t * 0.5), paint);
              } else {
                canvas.drawCircle(Offset.zero, radius * (1 - t * 0.6), paint);
              }
            },
          ),
        );
      },
    ),
  );
}

void _drawStar(Canvas canvas, double r, Paint paint) {
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final a = i * pi / 4;
    final d = i.isEven ? r : r * 0.4;
    final p = Offset(cos(a) * d, sin(a) * d);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  canvas.drawPath(path, paint);
}

/// 条纹糖引爆时的横/竖光束。
class BeamEffect extends PositionComponent {
  BeamEffect({
    required Vector2 center,
    required this.horizontal,
    required this.length,
    required this.thickness,
  }) : super(position: center, anchor: Anchor.center, priority: 55);

  final bool horizontal;
  final double length;
  final double thickness;
  double _t = 0;
  static const _life = 0.35;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _life).clamp(0.0, 1.0);
    final grow = Curves.easeOutCubic.transform(min(1, p * 2.2));
    final fade = 1 - Curves.easeInQuad.transform(p);
    final len = length * grow;
    final th = thickness * (1 - p * 0.4);
    final rect = horizontal
        ? Rect.fromCenter(center: Offset.zero, width: len, height: th)
        : Rect.fromCenter(center: Offset.zero, width: th, height: len);
    final paint = Paint()
      ..shader = Gradient.linear(
        horizontal ? rect.centerLeft : rect.topCenter,
        horizontal ? rect.centerRight : rect.bottomCenter,
        [
          Color.fromRGBO(255, 255, 255, 0),
          Color.fromRGBO(255, 255, 255, 0.95 * fade),
          Color.fromRGBO(255, 255, 255, 0),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(th / 2)),
      paint,
    );
    // 中心亮核
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(th * 0.3),
        Radius.circular(th / 2),
      ),
      Paint()..color = Color.fromRGBO(255, 240, 180, 0.8 * fade),
    );
  }
}

/// 包装糖 / 炸弹的圆形冲击波。
class ShockwaveEffect extends PositionComponent {
  ShockwaveEffect({required Vector2 center, required this.maxRadius})
      : super(position: center, anchor: Anchor.center, priority: 55);

  final double maxRadius;
  double _t = 0;
  static const _life = 0.4;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _life).clamp(0.0, 1.0);
    final r = maxRadius * Curves.easeOutCubic.transform(p);
    final fade = 1 - p;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxRadius * 0.12 * fade + 2
        ..color = Color.fromRGBO(255, 255, 255, 0.9 * fade),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxRadius * 0.06 * fade + 1
        ..color = Color.fromRGBO(255, 200, 80, 0.7 * fade),
    );
  }
}

/// 彩球引爆时射向各目标的闪电链。
class LightningEffect extends PositionComponent {
  LightningEffect({required Vector2 from, required this.targets})
      : super(position: from, priority: 58);

  final List<Vector2> targets;
  double _t = 0;
  static const _life = 0.45;
  late final List<List<Offset>> _bolts;

  @override
  void onLoad() {
    _bolts = targets.map((t) {
      final rel = t - position;
      final segs = <Offset>[Offset.zero];
      const n = 6;
      for (var i = 1; i < n; i++) {
        final f = i / n;
        final base = Offset(rel.x * f, rel.y * f);
        final jitter = rel.length * 0.08;
        segs.add(base +
            Offset(
              (_rng.nextDouble() - 0.5) * jitter,
              (_rng.nextDouble() - 0.5) * jitter,
            ));
      }
      segs.add(Offset(rel.x, rel.y));
      return segs;
    }).toList();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _life).clamp(0.0, 1.0);
    final fade = 1 - Curves.easeInQuad.transform(p);
    for (final bolt in _bolts) {
      final path = Path()..moveTo(0, 0);
      for (final seg in bolt) {
        path.lineTo(seg.dx, seg.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * fade + 0.5
          ..color = Color.fromRGBO(200, 240, 255, 0.9 * fade),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Color.fromRGBO(255, 255, 255, fade),
      );
    }
  }
}

/// 连锁 / 得分飘字。
class FloatingText extends TextComponent {
  FloatingText({
    required String text,
    required Vector2 at,
    Color color = const Color(0xFFFFFFFF),
    double fontSize = 28,
  }) : super(
          text: text,
          position: at,
          anchor: Anchor.center,
          priority: 70,
          textRenderer: TextPaint(
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              shadows: const [
                Shadow(color: Color(0xAA000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
          ),
        );

  double _t = 0;
  static const _life = 0.9;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= 55 * dt;
    if (_t < 0.15) {
      scale = Vector2.all(Curves.easeOutBack.transform(_t / 0.15));
    } else if (_t > _life - 0.25) {
      final f = ((_life - _t) / 0.25).clamp(0.0, 1.0);
      scale = Vector2.all(f * 0.4 + 0.6);
    }
    if (_t >= _life) removeFromParent();
  }
}
