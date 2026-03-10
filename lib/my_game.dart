import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/asteroid.dart';
import 'components/audio_manager.dart';
import 'components/pickup.dart';
import 'components/player.dart';
import 'components/star.dart';
import 'components/touch_area.dart';

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late TouchArea touchArea;
  late SpawnComponent _asteroidSpawner;
  late SpawnComponent _pickupSpawner;
  final Random _random = Random();
  int _score = 0;
  late TextComponent _scoreDisplay;
  final List<String> playerColors = ['blue', 'red', 'green', 'purple'];
  int playerColorIndex = 0;
  late final AudioManager audioManager;

  @override
  FutureOr<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();

    // initialize the audio manager and play the music
    audioManager = AudioManager();
    await add(audioManager);
    audioManager.playMusic();

    _createStars();

    return super.onLoad();
  }

  Future<void> startGame() async {
    await _createPlayer();
    _createTouchArea();
    _createAsteroidSpawner();
    _createPickupSpawner();
    _createScoreDisplay();
  }

  Future<void> _createPlayer() async {
    player = Player()
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y * 0.8);
    add(player);
  }

  void _createTouchArea() {
    touchArea = TouchArea();
    add(touchArea);
  }

  void _createAsteroidSpawner() {
    _asteroidSpawner = SpawnComponent.periodRange(
      factory: (index) => Asteroid(position: _generateSpawnPosition()),
      minPeriod: 1.5,
      maxPeriod: 2.5,
      selfPositioning: true,
    );
    add(_asteroidSpawner);
  }

  void _createPickupSpawner() {
    _pickupSpawner = SpawnComponent.periodRange(
      factory: (index) => Pickup(
        position: _generateSpawnPosition(),
        pickupType:
            PickupType.values[_random.nextInt(PickupType.values.length)],
      ),
      minPeriod: 5.0,
      maxPeriod: 7.0,
      selfPositioning: true,
    );
    add(_pickupSpawner);
  }

  Vector2 _generateSpawnPosition() {
    return Vector2(10 + _random.nextDouble() * (size.x - 10 * 2), -100);
  }

  void _createScoreDisplay() {
    _score = 0;

    _scoreDisplay = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 30),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 2),
          ],
        ),
      ),
    );

    add(_scoreDisplay);
  }

  void incrementScore(int amount) {
    _score += amount;
    _scoreDisplay.text = _score.toString();

    // Guard against stacking hundreds of effects when many points are scored
    // in rapid succession (e.g. bomb or asteroid split).
    if (_scoreDisplay.children.whereType<ScaleEffect>().isEmpty) {
      _scoreDisplay.add(
        ScaleEffect.to(
          Vector2.all(1.2),
          EffectController(
            duration: 0.05,
            alternate: true,
            curve: Curves.easeInOut,
          ),
        ),
      );
    }
  }

  void _createStars() {
    for (int i = 0; i < 50; i++) {
      add(Star()..priority = -10);
    }
  }

  void playerDied() {
    overlays.add('GameOver');
    pauseEngine();
  }

  Future<void> restartGame() async {
    // remove all gameplay components except the background stars
    children.whereType<PositionComponent>().toList().forEach((component) {
      if (component is! Star) {
        component.removeFromParent();
      }
    });

    // remove existing spawners so we can recreate them cleanly
    if (_asteroidSpawner.isMounted) {
      _asteroidSpawner.removeFromParent();
    }
    if (_pickupSpawner.isMounted) {
      _pickupSpawner.removeFromParent();
    }

    // reset the score; display will be recreated in startGame
    _score = 0;

    // Await startGame so the player and all components are fully created
    // before the engine resumes.
    await startGame();

    resumeEngine();
  }

  void quitGame() {
    // remove all gameplay components except the background stars
    children.whereType<PositionComponent>().forEach((component) {
      if (component is! Star) {
        component.removeFromParent();
      }
    });

    // remove existing spawners so nothing keeps spawning in the background
    if (_asteroidSpawner.isMounted) {
      _asteroidSpawner.removeFromParent();
    }
    if (_pickupSpawner.isMounted) {
      _pickupSpawner.removeFromParent();
    }

    // reset score; score display is recreated on next start
    _score = 0;

    // show the title overlay so the player can start a fresh game
    overlays.add('Title');

    resumeEngine();
  }
}
