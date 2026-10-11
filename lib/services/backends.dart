import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:chance/services/key_value_store.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/services/reminder_service.dart';
import 'package:chance/services/share_service.dart';

/// Real device services. `tool/dartpad_stubs/backends.dart` replaces this
/// file in the DartPad preview, where plugins aren't available.
class Backends {
  const Backends({required this.store, required this.purchases, required this.share, required this.reminders});

  final KeyValueStore store;
  final PurchaseService purchases;
  final ShareService share;
  final ReminderService reminders;

  /// `flutter run --dart-define=CHANCE_DEV=true` swaps the store for one
  /// where buying always succeeds, so locked lessons can be tried anywhere.
  static const bool devStore = bool.fromEnvironment('CHANCE_DEV');

  static Future<Backends> create() async {
    final prefs = await SharedPreferences.getInstance();
    final storeSupported =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    return Backends(
      store: _PrefsStore(prefs),
      purchases: devStore
          ? FakePurchaseService()
          : storeSupported
              ? StorePurchaseService()
              : FakePurchaseService(available: false),
      share: _PlusShareService(),
      reminders: storeSupported ? _LocalReminderService() : FakeReminderService(supported: false),
    );
  }
}

class _PrefsStore implements KeyValueStore {
  _PrefsStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class _PlusShareService implements ShareService {
  @override
  Future<void> shareText(String text) => SharePlus.instance.share(ShareParams(text: text));
}

/// Daily reminder via `flutter_local_notifications`, scheduled on the device.
class _LocalReminderService implements ReminderService {
  static const _id = 1;
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
        tzdata.initializeTimeZones();
        try {
          tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
        } on Object {
          tz.setLocalLocation(tz.UTC);
        }
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_notification'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
        );
      }();

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: false, sound: true) ?? false;
  }

  @override
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required bool skipToday,
    required String title,
    required String body,
  }) async {
    await _init();
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (skipToday || !first.isAfter(now)) first = first.add(const Duration(days: 1));
    await _plugin.cancel(id: _id);
    await _plugin.zonedSchedule(
      id: _id,
      scheduledDate: first,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: 'A daily nudge to keep your learning streak',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact is fine for a reminder and needs no exact-alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() async {
    await _init();
    await _plugin.cancel(id: _id);
  }
}

/// Google Play / App Store purchase via the `in_app_purchase` plugin.
///
/// Receipts are trusted on device. Add server-side verification before
/// relying on purchases for anything beyond unlocking offline content.
class StorePurchaseService implements PurchaseService {
  StorePurchaseService() {
    _sub = _iap.purchaseStream.listen(_onUpdates, onError: (Object _) => _finish(PurchaseOutcome.failed));
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  ProductDetails? _product;
  void Function(bool premium)? _onPremium;
  Completer<PurchaseOutcome>? _pending;

  Future<ProductDetails?> _loadProduct() async {
    if (_product != null) return _product;
    if (!await _iap.isAvailable()) return null;
    final response = await _iap.queryProductDetails({kPremiumProductId});
    if (response.productDetails.isEmpty) return null;
    return _product = response.productDetails.first;
  }

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<String?> price() async => (await _loadProduct())?.price;

  @override
  Future<PurchaseOutcome> buy() async {
    final product = await _loadProduct();
    if (product == null) return PurchaseOutcome.unavailable;
    _pending = Completer<PurchaseOutcome>();
    final started = await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    if (!started) _finish(PurchaseOutcome.failed);
    return _pending!.future;
  }

  @override
  Future<PurchaseOutcome> restore() async {
    if (!await _iap.isAvailable()) return PurchaseOutcome.unavailable;
    _pending = Completer<PurchaseOutcome>();
    await _iap.restorePurchases();
    // Restore reports nothing at all when there is nothing to restore.
    Future<void>.delayed(const Duration(seconds: 6), () => _finish(PurchaseOutcome.cancelled));
    return _pending!.future;
  }

  Future<void> _onUpdates(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      if (p.productID != kPremiumProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _onPremium?.call(true);
          _finish(p.status == PurchaseStatus.purchased ? PurchaseOutcome.purchased : PurchaseOutcome.restored);
        case PurchaseStatus.pending:
          _finish(PurchaseOutcome.pending);
        case PurchaseStatus.canceled:
          _finish(PurchaseOutcome.cancelled);
        case PurchaseStatus.error:
          _finish(PurchaseOutcome.failed);
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  void _finish(PurchaseOutcome outcome) {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(outcome);
  }

  @override
  void listen(void Function(bool premium) onPremium) => _onPremium = onPremium;

  @override
  void dispose() => _sub.cancel();
}
