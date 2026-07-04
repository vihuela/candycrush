import 'candy_spec.dart';

/// 游戏模式。
enum GameMode {
  /// 经典：限定步数内达到目标分数
  classic,

  /// 收集：限定步数内收集指定颜色糖果
  collect,

  /// 限时：60 秒内尽量拿高分，刷最佳纪录
  timed,
}

extension GameModeName on GameMode {
  String get label => switch (this) {
        GameMode.classic => '经典',
        GameMode.collect => '收集',
        GameMode.timed => '限时',
      };
}

/// 关卡配置。
class LevelConfig {
  const LevelConfig({
    required this.id,
    required this.moves,
    required this.targetScore,
    this.mode = GameMode.classic,
    this.colorCount = 6,
    this.collectGoals,
    this.timeLimit,
  });

  final int id;
  final GameMode mode;

  /// 步数上限（限时模式不使用）。
  final int moves;

  /// 目标分数：经典 = 过关线；限时 = 一星线；收集模式不使用。
  final int targetScore;
  final int colorCount;

  /// 收集模式目标：颜色 -> 数量。
  final Map<CandyColor, int>? collectGoals;

  /// 限时模式秒数。
  final int? timeLimit;

  /// 分数型星级线（经典/限时）。
  int starScore(int stars) => switch (stars) {
        1 => targetScore,
        2 => (targetScore * 1.6).round(),
        _ => (targetScore * 2.4).round(),
      };
}

/// 经典模式关卡。
const classicLevels = <LevelConfig>[
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

/// 收集模式关卡。
const collectLevels = <LevelConfig>[
  LevelConfig(
    id: 1,
    mode: GameMode.collect,
    moves: 24,
    targetScore: 0,
    colorCount: 4,
    collectGoals: {CandyColor.red: 25, CandyColor.yellow: 25},
  ),
  LevelConfig(
    id: 2,
    mode: GameMode.collect,
    moves: 24,
    targetScore: 0,
    colorCount: 5,
    collectGoals: {CandyColor.blue: 25, CandyColor.green: 25},
  ),
  LevelConfig(
    id: 3,
    mode: GameMode.collect,
    moves: 26,
    targetScore: 0,
    colorCount: 5,
    collectGoals: {CandyColor.orange: 30, CandyColor.red: 30},
  ),
  LevelConfig(
    id: 4,
    mode: GameMode.collect,
    moves: 26,
    targetScore: 0,
    colorCount: 6,
    collectGoals: {CandyColor.purple: 30, CandyColor.yellow: 30},
  ),
  LevelConfig(
    id: 5,
    mode: GameMode.collect,
    moves: 26,
    targetScore: 0,
    colorCount: 6,
    collectGoals: {CandyColor.blue: 35, CandyColor.red: 35},
  ),
  LevelConfig(
    id: 6,
    mode: GameMode.collect,
    moves: 28,
    targetScore: 0,
    colorCount: 6,
    collectGoals: {
      CandyColor.green: 28,
      CandyColor.orange: 28,
      CandyColor.purple: 28,
    },
  ),
  LevelConfig(
    id: 7,
    mode: GameMode.collect,
    moves: 28,
    targetScore: 0,
    colorCount: 6,
    collectGoals: {CandyColor.yellow: 40, CandyColor.blue: 40},
  ),
  LevelConfig(
    id: 8,
    mode: GameMode.collect,
    moves: 28,
    targetScore: 0,
    colorCount: 6,
    collectGoals: {CandyColor.red: 42, CandyColor.green: 42},
  ),
  LevelConfig(
    id: 9,
    mode: GameMode.collect,
    moves: 30,
    targetScore: 0,
    colorCount: 6,
    collectGoals: {
      CandyColor.purple: 32,
      CandyColor.orange: 32,
      CandyColor.blue: 32,
    },
  ),
  LevelConfig(
    id: 10,
    mode: GameMode.collect,
    moves: 30,
    targetScore: 0,
    colorCount: 6,
    collectGoals: {CandyColor.red: 48, CandyColor.purple: 48},
  ),
];

/// 限时挑战（单关，刷最佳纪录）。
const timedLevels = <LevelConfig>[
  LevelConfig(
    id: 1,
    mode: GameMode.timed,
    moves: 0,
    targetScore: 6000,
    colorCount: 6,
    timeLimit: 60,
  ),
];

List<LevelConfig> levelsOf(GameMode mode) => switch (mode) {
      GameMode.classic => classicLevels,
      GameMode.collect => collectLevels,
      GameMode.timed => timedLevels,
    };
