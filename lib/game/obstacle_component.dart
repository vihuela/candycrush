import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' show Canvas;

import 'candy_painter.dart';
import 'candy_spec.dart';

/// 冰冻/饼干障碍的渲染组件。
/// 冰冻画在糖果上层（priority 高），饼干占据空格。
class ObstacleComponent extends PositionComponent {
  ObstacleComponent({
    required this.type,
    required double cellSize,
  }) : super(
          size: Vector2.all(cellSize),
          anchor: Anchor.center,
          priority: type == ObstacleType.ice ? 20 : 5,
        );

  final ObstacleType type;

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    switch (type) {
      case ObstacleType.ice:
        CandyPainter.paintIce(canvas, size.x);
      case ObstacleType.cookie:
        CandyPainter.paintCookie(canvas, size.x);
      case ObstacleType.none:
        break;
    }
    canvas.restore();
  }

  /// 破碎动画：放大抖动后缩小消失。
  void playBreak() {
    add(SequenceEffect([
      ScaleEffect.to(Vector2.all(1.15), EffectController(duration: 0.07)),
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.18, curve: Curves.easeInBack),
      ),
      RemoveEffect(),
    ]));
  }
}
