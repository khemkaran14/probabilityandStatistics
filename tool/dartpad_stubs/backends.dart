import 'package:chance/services/key_value_store.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/services/reminder_service.dart';
import 'package:chance/services/share_service.dart';
import 'package:chance/services/sound_service.dart';

/// DartPad stand-in for lib/services/backends.dart: no plugins there, so
/// progress lives in memory and purchases always succeed.
class Backends {
  const Backends({
    required this.store,
    required this.purchases,
    required this.share,
    required this.reminders,
    required this.sounds,
  });

  final KeyValueStore store;
  final PurchaseService purchases;
  final ShareService share;
  final ReminderService reminders;
  final SoundService sounds;

  static Future<Backends> create() async => Backends(
        store: MemoryStore(),
        purchases: FakePurchaseService(),
        share: FakeShareService(),
        reminders: FakeReminderService(supported: false),
        sounds: FakeSoundService(),
      );
}
