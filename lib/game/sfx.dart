import 'package:flame_audio/flame_audio.dart';

/// 音效管理：预加载 + 免等待播放。
class Sfx {
  static bool _ready = false;
  static bool muted = false;

  static const _files = [
    'swap.wav',
    'pop1.wav',
    'pop2.wav',
    'pop3.wav',
    'stripe.wav',
    'wrap.wav',
    'bomb.wav',
    'shuffle.wav',
    'invalid.wav',
    'win.wav',
    'lose.wav',
  ];

  static Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll(_files);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static void _play(String file, {double volume = 1}) {
    if (!_ready || muted) return;
    try {
      FlameAudio.play(file, volume: volume);
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
  static void shuffleSound() => _play('shuffle.wav', volume: 0.8);
  static void invalid() => _play('invalid.wav', volume: 0.6);
  static void win() => _play('win.wav');
  static void lose() => _play('lose.wav');
}
