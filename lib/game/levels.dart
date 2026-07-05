import 'board.dart' show Pos;
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

/// 棋盘形状预设（8x8 内挖洞）。
class BoardShapes {
  /// 四角挖掉 2x2 -> 十字形
  static Set<Pos> cross() => {
        for (final r in [0, 1, 6, 7])
          for (final c in [0, 1, 6, 7]) Pos(r, c),
      };

  /// 中央挖 2x2 天井
  static Set<Pos> donut() => {
        const Pos(3, 3), const Pos(3, 4),
        const Pos(4, 3), const Pos(4, 4),
      };

  /// 上窄下宽的金字塔
  static Set<Pos> pyramid() => {
        for (var c = 0; c < 3; c++) Pos(0, c),
        for (var c = 5; c < 8; c++) Pos(0, c),
        for (var c = 0; c < 2; c++) Pos(1, c),
        for (var c = 6; c < 8; c++) Pos(1, c),
        Pos(2, 0), Pos(2, 7),
      };

  /// 菱形（四角大切角）
  static Set<Pos> diamond() => {
        for (var r = 0; r < 8; r++)
          for (var c = 0; c < 8; c++)
            if ((r - 3.5).abs() + (c - 3.5).abs() > 4.6) Pos(r, c),
      };

  /// 双塔（中间挖通道）
  static Set<Pos> towers() => {
        for (var r = 0; r < 5; r++) ...{Pos(r, 3), Pos(r, 4)},
      };
}

/// 障碍布局预设。
class ObstaclePresets {
  /// 中央 2x2 冰
  static Set<Pos> iceCenter() => {
        const Pos(3, 3), const Pos(3, 4),
        const Pos(4, 3), const Pos(4, 4),
      };

  /// 两侧冰柱
  static Set<Pos> icePillars() => {
        for (var r = 2; r < 6; r++) ...{Pos(r, 1), Pos(r, 6)},
      };

  /// 冰环
  static Set<Pos> iceRing() => {
        for (var i = 2; i < 6; i++) ...{
          Pos(2, i), Pos(5, i), Pos(i, 2), Pos(i, 5),
        },
      };

  /// 底部饼干墙
  static Set<Pos> cookieWall() => {
        for (var c = 1; c < 7; c++) Pos(5, c),
      };

  /// 四角饼干块
  static Set<Pos> cookieCorners() => {
        const Pos(1, 1), const Pos(1, 6),
        const Pos(6, 1), const Pos(6, 6),
      };

  /// 饼干十字
  static Set<Pos> cookieCross() => {
        const Pos(3, 2), const Pos(4, 2),
        const Pos(3, 5), const Pos(4, 5),
        const Pos(1, 3), const Pos(1, 4),
        const Pos(6, 3), const Pos(6, 4),
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
    this.holesBuilder,
    this.iceBuilder,
    this.cookieBuilder,
    this.clearObstacles = false,
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

  /// 异形棋盘挖洞 / 冰冻 / 饼干布局（函数以保持 const 构造）。
  final Set<Pos> Function()? holesBuilder;
  final Set<Pos> Function()? iceBuilder;
  final Set<Pos> Function()? cookieBuilder;

  /// true 时过关条件额外要求清完全部障碍。
  final bool clearObstacles;

  /// 分数型星级线（经典/限时）。
  int starScore(int stars) => switch (stars) {
        1 => targetScore,
        2 => (targetScore * 1.6).round(),
        _ => (targetScore * 2.4).round(),
      };
}

/// 经典模式关卡（20 关：平地 -> 异形 -> 冰冻 -> 饼干 -> 混合）。
final classicLevels = <LevelConfig>[
  // 入门
  const LevelConfig(id: 1, moves: 20, targetScore: 3000, colorCount: 4),
  const LevelConfig(id: 2, moves: 20, targetScore: 5000, colorCount: 5),
  const LevelConfig(id: 3, moves: 22, targetScore: 8000, colorCount: 5),
  // 异形棋盘登场
  LevelConfig(
      id: 4, moves: 22, targetScore: 10000, colorCount: 5,
      holesBuilder: BoardShapes.cross),
  const LevelConfig(id: 5, moves: 24, targetScore: 14000, colorCount: 6),
  LevelConfig(
      id: 6, moves: 24, targetScore: 15000, colorCount: 5,
      holesBuilder: BoardShapes.donut),
  // 冰冻登场
  LevelConfig(
      id: 7, moves: 24, targetScore: 16000, colorCount: 5,
      iceBuilder: ObstaclePresets.iceCenter, clearObstacles: true),
  LevelConfig(
      id: 8, moves: 26, targetScore: 20000, colorCount: 6,
      holesBuilder: BoardShapes.pyramid),
  LevelConfig(
      id: 9, moves: 26, targetScore: 20000, colorCount: 5,
      iceBuilder: ObstaclePresets.icePillars, clearObstacles: true),
  const LevelConfig(id: 10, moves: 26, targetScore: 26000, colorCount: 6),
  // 饼干登场
  LevelConfig(
      id: 11, moves: 24, targetScore: 18000, colorCount: 5,
      cookieBuilder: ObstaclePresets.cookieCorners, clearObstacles: true),
  LevelConfig(
      id: 12, moves: 26, targetScore: 24000, colorCount: 6,
      holesBuilder: BoardShapes.diamond),
  LevelConfig(
      id: 13, moves: 26, targetScore: 22000, colorCount: 5,
      cookieBuilder: ObstaclePresets.cookieWall, clearObstacles: true),
  LevelConfig(
      id: 14, moves: 28, targetScore: 28000, colorCount: 6,
      iceBuilder: ObstaclePresets.iceRing, clearObstacles: true),
  LevelConfig(
      id: 15, moves: 28, targetScore: 30000, colorCount: 6,
      holesBuilder: BoardShapes.towers),
  // 混合挑战
  LevelConfig(
      id: 16, moves: 28, targetScore: 30000, colorCount: 6,
      holesBuilder: BoardShapes.cross,
      iceBuilder: ObstaclePresets.iceCenter,
      clearObstacles: true),
  LevelConfig(
      id: 17, moves: 28, targetScore: 34000, colorCount: 6,
      cookieBuilder: ObstaclePresets.cookieCross, clearObstacles: true),
  LevelConfig(
      id: 18, moves: 30, targetScore: 38000, colorCount: 6,
      holesBuilder: BoardShapes.donut,
      cookieBuilder: ObstaclePresets.cookieCorners,
      clearObstacles: true),
  LevelConfig(
      id: 19, moves: 30, targetScore: 42000, colorCount: 6,
      iceBuilder: ObstaclePresets.icePillars,
      cookieBuilder: ObstaclePresets.cookieCorners,
      clearObstacles: true),
  LevelConfig(
      id: 20, moves: 32, targetScore: 50000, colorCount: 6,
      holesBuilder: BoardShapes.diamond,
      iceBuilder: ObstaclePresets.iceCenter,
      clearObstacles: true),
];

/// 收集模式关卡（15 关）。
final collectLevels = <LevelConfig>[
  const LevelConfig(
    id: 1, mode: GameMode.collect, moves: 24, targetScore: 0, colorCount: 4,
    collectGoals: {CandyColor.red: 25, CandyColor.yellow: 25},
  ),
  const LevelConfig(
    id: 2, mode: GameMode.collect, moves: 24, targetScore: 0, colorCount: 5,
    collectGoals: {CandyColor.blue: 25, CandyColor.green: 25},
  ),
  const LevelConfig(
    id: 3, mode: GameMode.collect, moves: 26, targetScore: 0, colorCount: 5,
    collectGoals: {CandyColor.orange: 30, CandyColor.red: 30},
  ),
  LevelConfig(
    id: 4, mode: GameMode.collect, moves: 26, targetScore: 0, colorCount: 5,
    collectGoals: const {CandyColor.purple: 28, CandyColor.yellow: 28},
    holesBuilder: BoardShapes.cross,
  ),
  const LevelConfig(
    id: 5, mode: GameMode.collect, moves: 26, targetScore: 0, colorCount: 6,
    collectGoals: {CandyColor.blue: 35, CandyColor.red: 35},
  ),
  LevelConfig(
    id: 6, mode: GameMode.collect, moves: 28, targetScore: 0, colorCount: 6,
    collectGoals: const {
      CandyColor.green: 28, CandyColor.orange: 28, CandyColor.purple: 28,
    },
    holesBuilder: BoardShapes.donut,
  ),
  LevelConfig(
    id: 7, mode: GameMode.collect, moves: 28, targetScore: 0, colorCount: 5,
    collectGoals: const {CandyColor.yellow: 40, CandyColor.blue: 40},
    iceBuilder: ObstaclePresets.iceCenter,
  ),
  const LevelConfig(
    id: 8, mode: GameMode.collect, moves: 28, targetScore: 0, colorCount: 6,
    collectGoals: {CandyColor.red: 42, CandyColor.green: 42},
  ),
  LevelConfig(
    id: 9, mode: GameMode.collect, moves: 30, targetScore: 0, colorCount: 6,
    collectGoals: const {
      CandyColor.purple: 32, CandyColor.orange: 32, CandyColor.blue: 32,
    },
    holesBuilder: BoardShapes.pyramid,
  ),
  LevelConfig(
    id: 10, mode: GameMode.collect, moves: 28, targetScore: 0, colorCount: 5,
    collectGoals: const {CandyColor.red: 40, CandyColor.purple: 40},
    cookieBuilder: ObstaclePresets.cookieCorners,
  ),
  LevelConfig(
    id: 11, mode: GameMode.collect, moves: 30, targetScore: 0, colorCount: 6,
    collectGoals: const {CandyColor.yellow: 45, CandyColor.green: 45},
    iceBuilder: ObstaclePresets.icePillars,
  ),
  LevelConfig(
    id: 12, mode: GameMode.collect, moves: 30, targetScore: 0, colorCount: 6,
    collectGoals: const {CandyColor.blue: 48, CandyColor.orange: 48},
    holesBuilder: BoardShapes.diamond,
  ),
  LevelConfig(
    id: 13, mode: GameMode.collect, moves: 30, targetScore: 0, colorCount: 6,
    collectGoals: const {
      CandyColor.red: 36, CandyColor.yellow: 36, CandyColor.purple: 36,
    },
    cookieBuilder: ObstaclePresets.cookieWall,
  ),
  LevelConfig(
    id: 14, mode: GameMode.collect, moves: 32, targetScore: 0, colorCount: 6,
    collectGoals: const {CandyColor.green: 52, CandyColor.blue: 52},
    iceBuilder: ObstaclePresets.iceRing,
  ),
  LevelConfig(
    id: 15, mode: GameMode.collect, moves: 32, targetScore: 0, colorCount: 6,
    collectGoals: const {
      CandyColor.orange: 40, CandyColor.purple: 40, CandyColor.red: 40,
    },
    holesBuilder: BoardShapes.towers,
    cookieBuilder: ObstaclePresets.cookieCorners,
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
