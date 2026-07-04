/// 关卡配置。
class LevelConfig {
  const LevelConfig({
    required this.id,
    required this.moves,
    required this.targetScore,
    this.colorCount = 6,
  });

  final int id;
  final int moves;
  final int targetScore;
  final int colorCount;

  /// 三星分数线。
  int starScore(int stars) => switch (stars) {
        1 => targetScore,
        2 => (targetScore * 1.6).round(),
        _ => (targetScore * 2.4).round(),
      };
}

const levels = <LevelConfig>[
  LevelConfig(id: 1, moves: 20, targetScore: 3000, colorCount: 4),
  LevelConfig(id: 2, moves: 20, targetScore: 5000, colorCount: 5),
  LevelConfig(id: 3, moves: 22, targetScore: 8000, colorCount: 5),
  LevelConfig(id: 4, moves: 22, targetScore: 12000, colorCount: 6),
  LevelConfig(id: 5, moves: 24, targetScore: 16000, colorCount: 6),
  LevelConfig(id: 6, moves: 24, targetScore: 20000, colorCount: 6),
  LevelConfig(id: 7, moves: 26, targetScore: 26000, colorCount: 6),
  LevelConfig(id: 8, moves: 26, targetScore: 32000, colorCount: 6),
  LevelConfig(id: 9, moves: 28, targetScore: 40000, colorCount: 6),
  LevelConfig(id: 10, moves: 30, targetScore: 50000, colorCount: 6),
];
