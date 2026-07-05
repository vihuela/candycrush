import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
              // 标题行 + 设置入口
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const Text(
                          '🍬 Sweet Crush',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
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
                  // 设置小入口（右上角）
                  Positioned(
                    right: 14,
                    top: 0,
                    child: GestureDetector(
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
                  ),
                ],
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x59120A28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: GameMode.values.map((m) {
          final selected = m == _mode;
          return GestureDetector(
            onTap: () => setState(() => _mode = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    switch (m) {
                      GameMode.classic => Icons.grid_view_rounded,
                      GameMode.collect => Icons.shopping_basket_rounded,
                      GameMode.timed => Icons.timer_rounded,
                    },
                    size: 17,
                    color: selected ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _modeLabel(m),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLevelGrid() {
    final list = levelsOf(_mode);
    final unlocked = Progress.unlockedLevel(_mode);
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.9,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final level = list[i];
        final isUnlocked = level.id <= unlocked;
        final stars = Progress.starsOf(_mode, level.id);
        return _LevelTile(
          level: level,
          unlocked: isUnlocked,
          stars: stars,
          onTap: isUnlocked ? () => _openLevel(level) : null,
        );
      },
    );
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

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.stars,
    this.onTap,
  });

  final LevelConfig level;
  final bool unlocked;
  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: unlocked
                ? (level.mode == GameMode.collect
                    ? [
                        const Color(0xFF6FD7A8),
                        const Color(0xFF3BB781),
                        const Color(0xFF1E8A64),
                      ]
                    : [
                        const Color(0xFFFF8AC5),
                        const Color(0xFFE255A8),
                        const Color(0xFF9C3FD9),
                      ])
                : [Colors.white12, Colors.white10],
            stops: unlocked ? const [0.0, 0.5, 1.0] : null,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: unlocked
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white24,
            width: 1.5,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: level.mode == GameMode.collect
                        ? const Color(0xFF14684A)
                        : const Color(0xFF6A2496),
                    offset: const Offset(0, 5),
                  ),
                  const BoxShadow(
                    color: Color(0x59000000),
                    offset: Offset(0, 10),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // 顶部光泽
            if (unlocked)
              Positioned(
                top: 5,
                left: 10,
                right: 10,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x4DFFFFFF), Color(0x00FFFFFF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (unlocked) ...[
                    Text(
                      '${level.id}',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              color: Color(0x66000000),
                              offset: Offset(0, 2),
                              blurRadius: 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    StarsRow(stars: stars, size: 17),
                  ] else
                    const Icon(Icons.lock_rounded,
                        color: Colors.white38, size: 34),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
