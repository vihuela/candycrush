import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/candy_painter.dart';
import '../game/candy_spec.dart';
import '../game/levels.dart';

/// 关卡进度存取（按模式分开存档）。
class Progress {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 经典模式沿用早期 key，保持老存档兼容
  static String _unlockKey(GameMode m) =>
      m == GameMode.classic ? 'unlocked' : 'unlocked_${m.name}';
  static String _starsKey(GameMode m, int id) =>
      m == GameMode.classic ? 'stars_$id' : 'stars_${m.name}_$id';

  static int unlockedLevel(GameMode mode) =>
      _prefs?.getInt(_unlockKey(mode)) ?? 1;

  static int starsOf(GameMode mode, int levelId) =>
      _prefs?.getInt(_starsKey(mode, levelId)) ?? 0;

  static Future<void> saveResult(GameMode mode, int levelId, int stars) async {
    if (_prefs == null) return;
    if (stars > starsOf(mode, levelId)) {
      await _prefs!.setInt(_starsKey(mode, levelId), stars);
    }
    if (levelId + 1 > unlockedLevel(mode)) {
      await _prefs!.setInt(_unlockKey(mode), levelId + 1);
    }
  }

  /// 限时挑战最佳纪录。返回是否刷新纪录。
  static int timedBest() => _prefs?.getInt('best_timed') ?? 0;

  static Future<bool> saveTimedBest(int score) async {
    if (_prefs == null || score <= timedBest()) return false;
    await _prefs!.setInt('best_timed', score);
    return true;
  }
}

/// 全局渐变背景：夜空紫 + 顶部光晕 + 漂浮圆点缀。
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2B1055),
            Color(0xFF4A1E7E),
            Color(0xFF34347E),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 顶部柔光
          const Positioned(
            top: -120,
            left: -60,
            right: -60,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x30FF9FF3), Color(0x00FF9FF3)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// 糖果风 3D 按钮：顶亮底暗渐变 + 底部厚边（立体压边）+ 顶部光泽。
class CandyButton extends StatefulWidget {
  const CandyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFFF9F1A),
    this.width,
    this.fontSize = 19,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final double? width;
  final double fontSize;

  @override
  State<CandyButton> createState() => _CandyButtonState();
}

class _CandyButtonState extends State<CandyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(widget.color);
    final top = hsl
        .withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0))
        .toColor();
    final bottom = hsl
        .withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0))
        .toColor();
    final rim = hsl
        .withLightness((hsl.lightness - 0.26).clamp(0.0, 1.0))
        .toColor();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.width,
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, widget.color, bottom],
            stops: const [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            // 立体厚边
            BoxShadow(color: rim, offset: Offset(0, _pressed ? 2 : 5)),
            // 落影
            BoxShadow(
              color: const Color(0x66000000),
              offset: Offset(0, _pressed ? 4 : 9),
              blurRadius: 12,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 顶部光泽条
            Positioned(
              top: 0,
              left: 8,
              right: 8,
              child: Container(
                height: widget.fontSize * 0.62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x59FFFFFF), Color(0x00FFFFFF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: const [
                  Shadow(
                      color: Color(0x73000000),
                      offset: Offset(0, 2),
                      blurRadius: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 迷你糖果图标（复用游戏内矢量绘制，用于收集目标 chips）。
class MiniCandy extends StatelessWidget {
  const MiniCandy({super.key, required this.color, this.size = 22});

  final CandyColor color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MiniCandyPainter(color),
    );
  }
}

class _MiniCandyPainter extends CustomPainter {
  _MiniCandyPainter(this.color);

  final CandyColor color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    CandyPainter.paint(canvas, size.width, color, SpecialType.none);
  }

  @override
  bool shouldRepaint(_MiniCandyPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 星星行。
class StarsRow extends StatelessWidget {
  const StarsRow({
    super.key,
    required this.stars,
    this.size = 44,
    this.glow = true,
  });

  final int stars;
  final double size;

  /// 发光阴影。滚动容器内建议关闭（Impeller 模糊层位移缺陷规避）。
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final lit = i < stars;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.06),
          child: Transform.translate(
            offset: Offset(0, i == 1 ? -size * 0.18 : 0),
            child: Icon(
              Icons.star_rounded,
              size: i == 1 ? size * 1.25 : size,
              color: lit ? const Color(0xFFFFD31A) : Colors.white24,
              shadows: lit && glow
                  ? const [
                      Shadow(color: Color(0xAAFF9F1A), blurRadius: 12),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
