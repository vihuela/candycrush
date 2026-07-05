import 'package:flutter/painting.dart';

/// 六种糖果颜色。
enum CandyColor { red, orange, yellow, green, blue, purple }

/// 特殊糖果类型。
enum SpecialType {
  none,
  stripedH, // 横条纹：引爆时清除整行
  stripedV, // 竖条纹：引爆时清除整列
  wrapped, // 包装糖：3x3 爆炸
  colorBomb, // 彩色炸弹：清除同色
}

/// 道具类型。
enum BoosterType { hammer, bomb, shuffle }

class CandyPalette {
  static const Map<CandyColor, Color> base = {
    CandyColor.red: Color(0xFFFF2D45),
    CandyColor.orange: Color(0xFFFF9500),
    CandyColor.yellow: Color(0xFFFFCE0A),
    CandyColor.green: Color(0xFF23CE58),
    CandyColor.blue: Color(0xFF1E9FFF),
    CandyColor.purple: Color(0xFFAE4BFF),
  };

  static Color light(CandyColor c) => _shift(base[c]!, 0.30);
  static Color dark(CandyColor c) => _shift(base[c]!, -0.28);

  static Color _shift(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }
}
