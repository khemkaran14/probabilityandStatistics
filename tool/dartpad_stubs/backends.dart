import 'package:chance/services/key_value_store.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/services/share_service.dart';

/// DartPad stand-in for lib/services/backends.dart: no plugins there, so
/// progress lives in memory and purchases always succeed.
class Backends {
  const Backends({required this.store, required this.purchases, required this.share});

  final KeyValueStore store;
  final PurchaseService purchases;
  final ShareService share;

  static Future<Backends> create() async => Backends(
        store: MemoryStore(),
        purchases: FakePurchaseService(),
        share: FakeShareService(),
      );
}
