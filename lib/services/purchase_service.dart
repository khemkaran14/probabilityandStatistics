/// Product id of the one-time "unlock everything" purchase. Create a
/// non-consumable / managed product with this id in Play Console and
/// App Store Connect.
const String kPremiumProductId = 'chance_premium_unlock';

enum PurchaseOutcome { purchased, restored, cancelled, pending, failed, unavailable }

/// One-time premium unlock.
abstract class PurchaseService {
  /// Whether the store can be used on this device.
  Future<bool> isAvailable();

  /// Localised price, e.g. "₹299.00", or null if it can't be loaded.
  Future<String?> price();

  Future<PurchaseOutcome> buy();

  Future<PurchaseOutcome> restore();

  /// Called with true whenever the store reports an owned premium unlock,
  /// including purchases that finish while the app was closed.
  void listen(void Function(bool premium) onPremium);

  void dispose();
}

/// Store stand-in for tests, web and the DartPad preview. Every purchase
/// succeeds instantly so the unlocked flow can be tried.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({this.available = true});

  final bool available;
  void Function(bool premium)? _onPremium;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> price() async => available ? '\$4.99' : null;

  @override
  Future<PurchaseOutcome> buy() async {
    if (!available) return PurchaseOutcome.unavailable;
    _onPremium?.call(true);
    return PurchaseOutcome.purchased;
  }

  @override
  Future<PurchaseOutcome> restore() async => available ? PurchaseOutcome.cancelled : PurchaseOutcome.unavailable;

  @override
  void listen(void Function(bool premium) onPremium) => _onPremium = onPremium;

  @override
  void dispose() => _onPremium = null;
}
