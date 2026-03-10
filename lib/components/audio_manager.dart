import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';

class AudioManager extends Component {
  bool musicEnabled = true;
  bool soundsEnabled = true;


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

    return super.onLoad();
  }

  void playMusic() {
    if (musicEnabled) {
      FlameAudio.bgm.play('music.ogg');
    }
  }

  void playSound(String sound) {
    if (!soundsEnabled) return;

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
}
