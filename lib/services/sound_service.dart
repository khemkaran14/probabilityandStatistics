/// The app's short sound effects.
enum Sfx { correct, wrong, finish }

/// Plays sound effects.
abstract class SoundService {
  Future<void> play(Sfx sfx);
}

/// Records what would have played. Used by tests and DartPad.
class FakeSoundService implements SoundService {
  final List<Sfx> played = [];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);
}
