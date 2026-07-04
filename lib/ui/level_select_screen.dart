import 'package:flutter/material.dart';

import '../game/levels.dart';
import 'common.dart';
import 'game_screen.dart';

/// 关卡选择页。
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  Widget build(BuildContext context) {
    final unlocked = Progress.unlockedLevel();
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
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '甜蜜消消乐',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (context, i) {
                    final level = levels[i];
                    final isUnlocked = level.id <= unlocked;
                    final stars = Progress.starsOf(level.id);
                    return _LevelTile(
                      level: level,
                      unlocked: isUnlocked,
                      stars: stars,
                      onTap: isUnlocked
                          ? () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(level: level),
                                ),
                              );
                              setState(() {});
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
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
                ? [
                    const Color(0xFFFF8AC5),
                    const Color(0xFFE255A8),
                    const Color(0xFF9C3FD9),
                  ]
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
              ? const [
                  BoxShadow(color: Color(0xFF6A2496), offset: Offset(0, 5)),
                  BoxShadow(
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
