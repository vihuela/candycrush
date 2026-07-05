import 'package:flame_audio/flame_audio.dart';

/// 音效管理。
///
/// 高频音效（pop/swap 等）使用 [AudioPool] 预热复用播放器——
/// `FlameAudio.play` 每次新建 AudioPlayer，在 Android 上是主线程重操作，
/// 连击时密集触发会掉帧。
class Sfx {
  static bool _ready = false;
  static bool muted = false;

  static final Map<String, AudioPool> _pools = {};

  /// 高频音效 -> 池大小
  static const _pooled = {
    'pop1.wav': 3,
    'pop2.wav': 3,
    'pop3.wav': 3,
    'swap.wav': 2,
    'invalid.wav': 2,
    'stripe.wav': 2,
    'wrap.wav': 2,
    'bomb.wav': 2,
    'ice.wav': 2,
    'cookie.wav': 2,
  };

  /// 低频音效，普通播放即可
  static const _oneshot = ['shuffle.wav', 'win.wav', 'lose.wav'];

  static Future<void> init() async {
    try {
      for (final entry in _pooled.entries) {
        _pools[entry.key] =
            await FlameAudio.createPool(entry.key, maxPlayers: entry.value);
      }
      await FlameAudio.audioCache.loadAll(_oneshot);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static void _play(String file, {double volume = 1}) {
    if (!_ready || muted) return;
    try {
      final pool = _pools[file];
      if (pool != null) {
        pool.start(volume: volume);
      } else {
        FlameAudio.play(file, volume: volume);
      }
    } catch (_) {}
  }

  static void swap() => _play('swap.wav', volume: 0.7);

  /// 连锁越高音调文件越高。
  static void pop(int cascade) {
    final n = cascade.clamp(1, 3);
    _play('pop$n.wav', volume: 0.8);
  }

  static void stripe() => _play('stripe.wav');
  static void wrap() => _play('wrap.wav');
  static void bomb() => _play('bomb.wav');
  static void ice() => _play('ice.wav', volume: 0.8);
  static void cookie() => _play('cookie.wav', volume: 0.9);
  static void shuffleSound() => _play('shuffle.wav', volume: 0.8);
  static void invalid() => _play('invalid.wav', volume: 0.6);
  static void win() => _play('win.wav');
  static void lose() => _play('lose.wav');
}
