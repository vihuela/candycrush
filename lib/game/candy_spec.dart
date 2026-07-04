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
    CandyColor.red: Color(0xFFFF3B4E),
    CandyColor.orange: Color(0xFFFF9F1A),
    CandyColor.yellow: Color(0xFFFFD31A),
    CandyColor.green: Color(0xFF35D461),
    CandyColor.blue: Color(0xFF2FA8FF),
    CandyColor.purple: Color(0xFFB45CFF),
  };

  static Color light(CandyColor c) => _shift(base[c]!, 0.30);
  static Color dark(CandyColor c) => _shift(base[c]!, -0.28);

  static Color _shift(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }
}
