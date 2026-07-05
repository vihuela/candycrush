import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../game/candy_spec.dart';
import '../game/levels.dart';
import '../i18n/strings.dart';
import 'common.dart';
import 'game_screen.dart';

const _termsUrl = 'https://puzzle-game-legal.pages.dev/terms';
const _privacyUrl = 'https://puzzle-game-legal.pages.dev/privacy';

/// 关卡选择页：顶部模式切换（经典 / 收集 / 限时）+ 设置入口。
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  GameMode _mode = GameMode.classic;
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  void _switchMode(GameMode m) {
    if (m == _mode) return;
    _scroll?.dispose();
    _scroll = null;
    setState(() => _mode = m);
  }

  Future<void> _openLevel(LevelConfig level) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(level: level)),
    );
    setState(() {});
  }

  String _modeLabel(GameMode m) => switch (m) {
        GameMode.classic => Lang.t.modeClassic,
        GameMode.collect => Lang.t.modeCollect,
        GameMode.timed => Lang.t.modeTimed,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // 标题行 + 设置入口（两侧对称占位，标题永不与按钮重叠）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 40), // 与右侧设置按钮对称，保持标题居中
                    Expanded(
                      child: Column(
                        children: [
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '🍬 Sweet Crush',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Color(0xFF7B2FBF),
                                      offset: Offset(0, 4),
                                      blurRadius: 0),
                                  Shadow(
                                      color: Color(0x66000000),
                                      offset: Offset(0, 8),
                                      blurRadius: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Lang.t.subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 设置小入口
                    GestureDetector(
                      onTap: _showSettingsMenu,
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.settings_rounded,
                            color: Colors.white70, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildModeTabs(),
              const SizedBox(height: 16),
              Expanded(
                child: _mode == GameMode.timed
                    ? _buildTimedBody()
                    : _buildLevelGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- 设置菜单 ----------

  void _showSettingsMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF35275E), Color(0xFF241543)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: Colors.white38)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.translate_rounded,
                      color: Colors.white70, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    Lang.t.language,
                    style: const TextStyle(
                        fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppLang.values.map((l) {
                  final selected = Lang.notifier.value == l;
                  return GestureDetector(
                    onTap: () async {
                      await Lang.set(l);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFF8AC5),
                                  Color(0xFFB44BE0)
                                ],
                              )
                            : null,
                        color: selected ? null : Colors.white12,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.white24,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        l.nativeName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color:
                              selected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              const Divider(color: Colors.white12, height: 1),
              _menuRow(
                icon: Icons.description_rounded,
                label: Lang.t.terms,
                onTap: () => launchUrl(
                  Uri.parse(_termsUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              _menuRow(
                icon: Icons.privacy_tip_rounded,
                label: Lang.t.privacy,
                onTap: () => launchUrl(
                  Uri.parse(_privacyUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 19),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
            const Spacer(),
            const Icon(Icons.open_in_new_rounded,
                color: Colors.white38, size: 17),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0x59120A28),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        // 三等分，长文案（如日语）自动缩放，不会溢出
        child: Row(
          children: GameMode.values.map((m) {
            final selected = m == _mode;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _switchMode(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFF8AC5), Color(0xFFB44BE0)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                                color: Color(0x66E255A8), blurRadius: 10),
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          switch (m) {
                            GameMode.classic => Icons.grid_view_rounded,
                            GameMode.collect =>
                              Icons.shopping_basket_rounded,
                            GameMode.timed => Icons.timer_rounded,
                          },
                          size: 17,
                          color: selected ? Colors.white : Colors.white54,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _modeLabel(m),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color:
                                selected ? Colors.white : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLevelGrid() {
    final list = levelsOf(_mode);
    final unlocked = Progress.unlockedLevel(_mode);
    // 蜿蜒路径地图：S 形节点排布
    const spacing = 148.0;
    const topPad = 60.0;
    final contentHeight = topPad + spacing * list.length + 90;
    // 关卡节点横向位置模式（0~1 宽度系数）
    const xPattern = [0.26, 0.54, 0.78, 0.54];

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      // 首次进入自动定位到当前关卡附近
      _scroll ??= ScrollController(
        initialScrollOffset: (topPad +
                (unlocked - 1) * spacing -
                constraints.maxHeight * 0.45)
            .clamp(0.0, max(0.0, contentHeight - constraints.maxHeight)),
      );
      final points = [
        for (var i = 0; i < list.length; i++)
          Offset(w * xPattern[i % xPattern.length], topPad + i * spacing),
      ];
      final endPoint = Offset(
        w * xPattern[list.length % xPattern.length],
        topPad + list.length * spacing,
      );
      return SingleChildScrollView(
        controller: _scroll,
        child: SizedBox(
          height: contentHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 背景装饰糖果
              ..._decorCandies(w, contentHeight),
              // 蜿蜒虚线路径
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter([...points, endPoint]),
                ),
              ),
              // 关卡节点
              for (var i = 0; i < list.length; i++)
                _positionNode(
                  points[i],
                  _LevelNode(
                    id: list[i].id,
                    color: _nodeColor(i),
                    stars: Progress.starsOf(_mode, list[i].id),
                    state: list[i].id < unlocked
                        ? _NodeState.done
                        : list[i].id == unlocked
                            ? _NodeState.current
                            : _NodeState.locked,
                    onTap: list[i].id <= unlocked
                        ? () => _openLevel(list[i])
                        : null,
                  ),
                ),
              // 路径终点：敬请期待
              Positioned(
                left: endPoint.dx - 90,
                top: endPoint.dy - 16,
                child: SizedBox(
                  width: 180,
                  child: Column(
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 30)),
                      const SizedBox(height: 4),
                      Text(
                        Lang.t.comingSoon,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _positionNode(Offset center, _LevelNode node) {
    // 节点区域固定 128x128，居中于路径点
    return Positioned(
      left: center.dx - 64,
      top: center.dy - 56,
      child: SizedBox(width: 128, height: 128, child: Center(child: node)),
    );
  }

  Color _nodeColor(int index) {
    const cycle = [
      CandyColor.red,
      CandyColor.orange,
      CandyColor.green,
      CandyColor.blue,
      CandyColor.purple,
    ];
    return CandyPalette.base[cycle[index % cycle.length]]!;
  }

  /// 背景低透明度装饰糖果。
  List<Widget> _decorCandies(double w, double h) {
    final rng = Random(11);
    final colors = CandyColor.values;
    final widgets = <Widget>[];
    final count = (h / 170).round();
    for (var i = 0; i < count; i++) {
      final leftSide = i.isEven;
      final x = leftSide
          ? w * (0.02 + rng.nextDouble() * 0.08)
          : w * (0.84 + rng.nextDouble() * 0.08);
      final y = h * (i + 0.5) / count + (rng.nextDouble() - 0.5) * 40;
      final size = 26.0 + rng.nextDouble() * 26;
      widgets.add(Positioned(
        left: x,
        top: y,
        child: RepaintBoundary(
          child: Opacity(
            opacity: 0.16,
            child: Transform.rotate(
              angle: (rng.nextDouble() - 0.5) * 1.2,
              child: MiniCandy(
                color: colors[rng.nextInt(colors.length)],
                size: size,
              ),
            ),
          ),
        ),
      ));
    }
    return widgets;
  }

  Widget _buildTimedBody() {
    final best = Progress.timedBest();
    final level = timedLevels.first;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF35386E), Color(0xFF241543)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white38, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏱️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 10),
            Text(
              Lang.t.timedTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Lang.t.timedDesc(level.timeLimit ?? 60),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x40120A28),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFFD31A), size: 26),
                  const SizedBox(width: 10),
                  Text(
                    best > 0
                        ? '${Lang.t.bestPrefix}  $best'
                        : Lang.t.noRecord,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CandyButton(
              label: Lang.t.startChallenge,
              color: const Color(0xFFFF7043),
              width: 200,
              onTap: () => _openLevel(level),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NodeState { locked, current, done }

/// 关卡节点：糖果球按钮。
class _LevelNode extends StatefulWidget {
  const _LevelNode({
    required this.id,
    required this.color,
    required this.stars,
    required this.state,
    this.onTap,
  });

  final int id;
  final Color color;
  final int stars;
  final _NodeState state;
  final VoidCallback? onTap;

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.state == _NodeState.current) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.state == _NodeState.locked;
    final current = widget.state == _NodeState.current;
    final d = current ? 92.0 : (locked ? 66.0 : 80.0);
    final hsl = HSLColor.fromColor(widget.color);
    final top = hsl.withLightness((hsl.lightness + 0.16).clamp(0.0, 1.0)).toColor();
    final bottom = hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
    final rim = hsl.withLightness((hsl.lightness - 0.30).clamp(0.0, 1.0)).toColor();

    final orb = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: locked
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x4DFFFFFF), Color(0x21FFFFFF)],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, widget.color, bottom],
                stops: const [0.0, 0.55, 1.0],
              ),
        border: Border.all(
          color: locked
              ? Colors.white24
              : Colors.white.withValues(alpha: 0.75),
          width: locked ? 1.5 : 2.5,
        ),
        boxShadow: locked
            ? null
            : [
                BoxShadow(color: rim, offset: const Offset(0, 5)),
                const BoxShadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 9),
                  blurRadius: 10,
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!locked)
            Positioned(
              top: d * 0.08,
              child: Container(
                width: d * 0.6,
                height: d * 0.26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(d * 0.15),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x7DFFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          locked
              ? const Icon(Icons.lock_rounded, color: Colors.white54, size: 26)
              : Text(
                  '${widget.id}',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: current ? 36 : 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                          color: Color(0x66000000),
                          offset: Offset(0, 2)),
                    ],
                  ),
                ),
        ],
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 当前关卡呼吸光环
            if (current && _pulse != null)
              AnimatedBuilder(
                animation: _pulse!,
                builder: (context, _) {
                  final t = _pulse!.value;
                  return Container(
                    width: d + 14 + 22 * t,
                    height: d + 14 + 22 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55 * (1 - t)),
                        width: 3,
                      ),
                    ),
                  );
                },
              ),
            orb,
            // 已通关星级，压在节点下缘
            if (widget.state == _NodeState.done && widget.stars > 0)
              Positioned(
                bottom: 4,
                child: StarsRow(
                    stars: widget.stars, size: 16, glow: false),
              ),
          ],
        ),
      ),
    );
  }
}

/// 关卡间蜿蜒虚线路径。
class _PathPainter extends CustomPainter {
  _PathPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    // 经典中点平滑：以节点为控制点、相邻中点为端点，保证不产生回环
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // 宽底路径
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x12FFFFFF),
    );
    // 沿路径的圆点虚线
    final dotPaint = Paint()..color = const Color(0x59FFFFFF);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final pos = metric.getTangentForOffset(dist)?.position;
        if (pos != null) {
          canvas.drawCircle(pos, 3.4, dotPaint);
        }
        dist += 26;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) =>
      oldDelegate.points != points;
}
