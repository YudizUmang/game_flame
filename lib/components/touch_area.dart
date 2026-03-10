import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../my_game.dart';

/// Full-screen invisible input layer.
/// Only touches/drags that BEGIN in the bottom half of the screen are
/// recognised — matching the natural thumb zone on a phone. Once a drag
/// has started it is tracked wherever the finger moves.
class TouchArea extends PositionComponent
    with HasGameReference<MyGame>, TapCallbacks, DragCallbacks {
  Vector2? _touchTarget;

  /// The current finger position in canvas coordinates, or null when no
  /// finger is down.
  Vector2? get touchTarget => _touchTarget;

  @override
  void onLoad() {
    // Cover the whole canvas so events are always routed here.
    size = game.size;
  }

  // ── Tap (press without significant movement) ──────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    if (_isBottomHalf(event.localPosition)) {
      _touchTarget = event.localPosition.clone();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _touchTarget = null;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _touchTarget = null;
  }

  // ── Drag (press + move) ───────────────────────────────────────────────────

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_isBottomHalf(event.localPosition)) {
      _touchTarget = event.localPosition.clone();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Accumulate delta to track absolute finger position.
    // Once a drag is accepted, follow the finger anywhere on screen.
    if (_touchTarget != null) {
      _touchTarget = _touchTarget! + event.localDelta;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _touchTarget = null;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _touchTarget = null;
  }

  // ─────────────────────────────────────────────────────────────────────────

  bool _isBottomHalf(Vector2 localPos) => localPos.y >= game.size.y / 2;
}
