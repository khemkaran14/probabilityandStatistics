import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/galton_board.dart';

/// Every lesson with a built animation, keyed by its catalogue id.
/// Add new lessons here as they're built.
final Map<String, LessonSpec> lessonRegistry = {
  galtonLesson.id: galtonLesson,
};
