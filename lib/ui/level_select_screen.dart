import 'package:flutter/material.dart';

import '../game/levels.dart';
import 'common.dart';
import 'game_screen.dart';

/// 关卡选择页：顶部模式切换（经典 / 收集 / 限时）。
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                '🍬 Sweet Crush',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0xFF7B2FBF), offset: Offset(0, 4), blurRadius: 0),
                    Shadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 16),
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
                    m.label,
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
            const Text(
              '限时挑战',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${level.timeLimit} 秒内尽可能多得分\n连锁和特殊糖是高分关键！',
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
                    best > 0 ? '最佳纪录  $best' : '暂无纪录',
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
              label: '开始挑战',
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
