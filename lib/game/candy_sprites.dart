import 'dart:ui' as ui;

import 'candy_painter.dart';
import 'candy_spec.dart';

/// 糖果纹理缓存：每种 (颜色, 特殊类型, 尺寸) 只矢量绘制一次，
/// 之后每帧仅做贴图，避免 64 颗糖每帧跑渐变+模糊导致连击掉帧。
class CandySprites {
  /// 纹理画布相对格子的放大系数（容纳投影 / 糖纸耳朵 / 光晕）。
  static const double pad = 1.6;

  /// 设备像素比，游戏加载时设置，保证纹理按物理像素渲染不发虚。
  static double dpr = 2;

  static final Map<String, ui.Image> _cache = {};

  static ui.Image of(CandyColor color, SpecialType special, double cellLogical) {
    final px = (cellLogical * dpr).round();
    final key = '${color.index}-${special.index}-$px';
    return _cache[key] ??= _render(color, special, px.toDouble());
  }

  /// 预热全部组合，避免首次出现特殊糖时的合成卡顿。
  static void warmUp(double cellLogical) {
    for (final c in CandyColor.values) {
      for (final s in [
        SpecialType.none,
        SpecialType.stripedH,
        SpecialType.stripedV,
        SpecialType.wrapped,
      ]) {
        of(c, s, cellLogical);
      }
    }
    of(CandyColor.red, SpecialType.colorBomb, cellLogical);
  }

  static ui.Image _render(CandyColor color, SpecialType special, double cellPx) {
    final side = (cellPx * pad).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.translate(side / 2, side / 2);
    CandyPainter.paint(canvas, cellPx, color, special);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(side, side);
    picture.dispose();
    return image;
  }
}
