import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';

import '../game/candy_spec.dart';
import '../game/levels.dart';
import '../game/match_game.dart';
import 'common.dart';

/// 对局页：Flame 画布 + HUD + 道具栏 + 结算弹窗。
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final LevelConfig level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late MatchGame game;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _resultShown = false;
    game = MatchGame(
      level: widget.level,
      onStateChanged: _onGameState,
    );
  }

  void _onGameState() {
    if (!mounted) return;
    setState(() {});
    if (game.status != GameStatus.playing && !_resultShown) {
      _resultShown = true;
      if (game.status == GameStatus.won) {
        Progress.saveResult(widget.level.id, game.stars);
      }
      // 稍等庆祝动画再弹结算
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _showResult();
      });
    }
  }

  Future<void> _showResult() async {
    final won = game.status == GameStatus.won;
    final hasNext = widget.level.id < levels.length;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => _ResultDialog(
        won: won,
        score: game.score,
        stars: game.stars,
        target: widget.level.targetScore,
        onNext: won && hasNext
            ? () {
                Navigator.of(ctx).pop();
                // 用下一关替换当前对局页
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        GameScreen(level: levels[widget.level.id]),
                  ),
                );
              }
            : null,
        onRetry: () {
          Navigator.of(ctx).pop();
          setState(_newGame);
        },
        onExit: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (game.score / widget.level.targetScore).clamp(0.0, 1.0);
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHud(progress),
              Expanded(
                child: GameWidget(game: game),
              ),
              _buildBoosterBar(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        children: [
          Row(
            children: [
              _roundIcon(
                Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 10),
              _pill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swipe_rounded,
                        color: Color(0xFF7CE4FF), size: 19),
                    const SizedBox(width: 6),
                    Text(
                      '${game.movesLeft}',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: game.movesLeft <= 5
                            ? const Color(0xFFFF6E6E)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _pill(
                child: Text(
                  '第 ${widget.level.id} 关',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              _pill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Color(0xFFFFD31A), size: 19),
                    const SizedBox(width: 6),
                    Text(
                      '${game.score}',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 目标进度条：加高、圆头、光泽
          SizedBox(
            height: 18,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0x66120A28),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white24, width: 1.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerLeft,
                    widthFactor: progress <= 0 ? 0.001 : progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF8CF2A0),
                            Color(0xFF35D461),
                            Color(0xFF1FA84A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x8035D461), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '目标 ${widget.level.targetScore}',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _boosterButton(
            BoosterType.hammer,
            Icons.gavel_rounded,
            '锤子',
            const Color(0xFFFFA726),
          ),
          _boosterButton(
            BoosterType.bomb,
            Icons.local_fire_department_rounded,
            '炸弹',
            const Color(0xFFFF5252),
          ),
          _boosterButton(
            BoosterType.shuffle,
            Icons.cached_rounded,
            '洗牌',
            const Color(0xFF40C4FF),
          ),
        ],
      ),
    );
  }

  Widget _boosterButton(
    BoosterType type,
    IconData icon,
    String label,
    Color color,
  ) {
    final count = game.boosterCounts[type] ?? 0;
    final armed = game.armedBooster == type;
    final enabled = count > 0 && game.status == GameStatus.playing;
    final hsl = HSLColor.fromColor(color);
    final top = hsl.withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0)).toColor();
    final bottom = hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
    final rim = hsl.withLightness((hsl.lightness - 0.30).clamp(0.0, 1.0)).toColor();

    return GestureDetector(
      onTap: enabled ? () => game.armBooster(type) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 圆形玻璃球按钮
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: enabled
                        ? [top, color, bottom]
                        : [Colors.white24, Colors.white12, Colors.white10],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: armed
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    width: armed ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    if (enabled)
                      BoxShadow(color: rim, offset: const Offset(0, 4)),
                    BoxShadow(
                      color: armed
                          ? color.withValues(alpha: 0.85)
                          : const Color(0x59000000),
                      blurRadius: armed ? 18 : 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 顶部光泽
                    Positioned(
                      top: 6,
                      child: Container(
                        width: 38,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      icon,
                      color: enabled ? Colors.white : Colors.white38,
                      size: 30,
                      shadows: const [
                        Shadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 3),
                      ],
                    ),
                  ],
                ),
              ),
              // 数量徽标
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: enabled ? Colors.white : Colors.white30,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: enabled ? rim : Colors.black38,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            armed ? '点击目标' : label,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: armed
                  ? Colors.white
                  : (enabled ? Colors.white70 : Colors.white30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x40241543), Color(0x66120A28)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: child,
      );

  Widget _roundIcon(IconData icon, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x40241543), Color(0x66120A28)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.won,
    required this.score,
    required this.stars,
    required this.target,
    required this.onRetry,
    required this.onExit,
    this.onNext,
  });

  final bool won;
  final int score;
  final int stars;
  final int target;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  /// 有下一关时的回调；末关或失败为 null。
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final isLastLevelWin = won && onNext == null;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: won
                ? [const Color(0xFF7B3FE4), const Color(0xFF3E1E68)]
                : [const Color(0xFF4A4A6A), const Color(0xFF25253C)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white54, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won
                  ? (isLastLevelWin ? '👑 全部通关！' : '🎉 过关啦！')
                  : '😢 差一点点',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (won) StarsRow(stars: stars),
            if (won) const SizedBox(height: 16),
            Text(
              '得分  $score',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFD31A),
              ),
            ),
            Text(
              '目标  $target',
              style: const TextStyle(fontSize: 15, color: Colors.white60),
            ),
            const SizedBox(height: 24),
            // 主操作：过关 -> 下一关；失败 -> 重试；末关通关 -> 返回选关
            if (won && onNext != null)
              CandyButton(
                label: '下一关  ▶',
                color: const Color(0xFF35D461),
                width: 200,
                onTap: onNext!,
              )
            else if (won)
              CandyButton(
                label: '返回选关',
                color: const Color(0xFF35D461),
                width: 200,
                onTap: onExit,
              )
            else
              CandyButton(
                label: '重试',
                color: const Color(0xFF35D461),
                width: 200,
                onTap: onRetry,
              ),
            const SizedBox(height: 14),
            // 次要操作
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (won) ...[
                  _SecondaryButton(
                    icon: Icons.refresh_rounded,
                    label: '重玩',
                    onTap: onRetry,
                  ),
                  const SizedBox(width: 26),
                ],
                _SecondaryButton(
                  icon: Icons.home_rounded,
                  label: '返回',
                  onTap: onExit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 结算弹窗的次要操作：圆形图标按钮 + 小字标签。
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
