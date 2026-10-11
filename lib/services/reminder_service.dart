/// A daily "time to learn" notification at a fixed time of day.
abstract class ReminderService {
  /// Whether this device can show reminders at all (false on web).
  bool get supported;

  /// Asks the user for permission to notify. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Replaces any reminder with one every day at [hour]:[minute] local time.
  /// With [skipToday] the first one comes tomorrow.
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required bool skipToday,
    required String title,
    required String body,
  });

  Future<void> cancel();
}

/// Records what would have been scheduled. Used by tests and DartPad.
class FakeReminderService implements ReminderService {
  FakeReminderService({this.supported = true, this.grant = true});

  @override
  final bool supported;

  /// What [requestPermission] answers.
  bool grant;

  /// The current reminder as (hour, minute, skipToday), or null if none.
  (int, int, bool)? scheduled;
  String? body;

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required bool skipToday,
    required String title,
    required String body,
  }) async {
    scheduled = (hour, minute, skipToday);
    this.body = body;
  }

  @override
  Future<void> cancel() async => scheduled = null;
}
