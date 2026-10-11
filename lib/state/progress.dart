import 'package:flutter/foundation.dart';

/// Very small in-memory progress store (XP + finished lessons).
/// Will be swapped for on-device storage later.
class Progress {
  Progress._();

  static final ValueNotifier<int> xp = ValueNotifier<int>(0);
  static final ValueNotifier<Set<String>> completed =
      ValueNotifier<Set<String>>(<String>{});

  static void complete(String lessonId, int reward) {
    if (completed.value.contains(lessonId)) return;
    completed.value = {...completed.value, lessonId};
    xp.value += reward;
  }
}
