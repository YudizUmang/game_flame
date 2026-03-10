import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';

class AudioManager extends Component {
  bool musicEnabled = true;
  bool soundsEnabled = true;

  // Pool frequently-triggered SFX to avoid creating/queuing too many players.
  final Map<String, AudioPool> _sfxPools = {};

  // Simple per-sound throttle (ms) to prevent "laser" spam from overwhelming
  // the audio backend over long sessions.
  final Map<String, int> _lastPlayedAtMs = {};
  final Map<String, int> _minIntervalMs = const {
    // Very frequent events
    'laser': 120,
    'hit': 60,
    // Bursty events
    'explode1': 80,
    'explode2': 80,
    'fire': 120,
    'collect': 120,
    // UI-ish
    'click': 150,
    'start': 250,
  };

  @override
  FutureOr<void> onLoad() async {
    FlameAudio.bgm.initialize();

    await FlameAudio.audioCache.loadAll([
      'click.ogg',
      'collect.ogg',
      'explode1.ogg',
      'explode2.ogg',
      'fire.ogg',
      'hit.ogg',
      'laser.ogg',
      'start.ogg',
    ]);

    // Keep total concurrent players low to avoid Android ENODEV (-19) errors.
    _sfxPools['click'] = await FlameAudio.createPool('click.ogg', maxPlayers: 1);
    _sfxPools['collect'] =
        await FlameAudio.createPool('collect.ogg', maxPlayers: 2);
    _sfxPools['explode1'] =
        await FlameAudio.createPool('explode1.ogg', maxPlayers: 2);
    _sfxPools['explode2'] =
        await FlameAudio.createPool('explode2.ogg', maxPlayers: 2);
    _sfxPools['fire'] = await FlameAudio.createPool('fire.ogg', maxPlayers: 1);
    _sfxPools['hit'] = await FlameAudio.createPool('hit.ogg', maxPlayers: 2);
    _sfxPools['laser'] =
        await FlameAudio.createPool('laser.ogg', maxPlayers: 1);
    _sfxPools['start'] =
        await FlameAudio.createPool('start.ogg', maxPlayers: 1);

    return super.onLoad();
  }

  void playMusic() {
    if (musicEnabled) {
      FlameAudio.bgm.play('music.ogg');
    }
  }

  void playSound(String sound) {
    if (!soundsEnabled) return;

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int minInterval = _minIntervalMs[sound] ?? 0;
    final int lastMs = _lastPlayedAtMs[sound] ?? 0;
    if (minInterval > 0 && (nowMs - lastMs) < minInterval) {
      return;
    }
    _lastPlayedAtMs[sound] = nowMs;

    final AudioPool? pool = _sfxPools[sound];
    if (pool != null) {
      pool.start();
      return;
    }

    // Fallback if a sound wasn't pooled for some reason.
    FlameAudio.play('$sound.ogg').ignore();
  }

  void toggleMusic() {
    musicEnabled = !musicEnabled;
    if (musicEnabled) {
      playMusic();
    } else {
      FlameAudio.bgm.stop();
    }
  }

  void toggleSounds() {
    soundsEnabled = !soundsEnabled;
  }

  /// Stop all active SFX pools and background music (call on game over / pause).
  void stopAll() {
    FlameAudio.bgm.stop();
    for (final pool in _sfxPools.values) {
      pool.dispose();
    }
    _sfxPools.clear();
  }

  @override
  void onRemove() {
    stopAll();
    super.onRemove();
  }
}
