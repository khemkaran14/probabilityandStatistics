import 'package:flutter/foundation.dart';

/// Base class every animated lesson extends.
///
/// The lesson screen owns a ticker and calls [advance] every frame while
/// [playing] is true, already multiplied by [speed]. Subclasses update their
/// state and call [notifyListeners] so painters and labels redraw.
abstract class LessonSim extends ChangeNotifier {
  bool playing = true;
  double speed = 1.0;

  /// Move the simulation forward by [dt] seconds (speed already applied).
  void advance(double dt);

  /// One small, visible step. Used by the "step" button while paused.
  void step();

  /// Back to the starting state.
  void reset();

  void togglePlay() {
    playing = !playing;
    notifyListeners();
  }

  void setSpeed(double value) {
    speed = value;
    notifyListeners();
  }
}
