import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:chance/services/account_service.dart';
import 'package:chance/services/key_value_store.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/services/reminder_service.dart';
import 'package:chance/services/share_service.dart';
import 'package:chance/services/sound_service.dart';

/// Real device services. `tool/dartpad_stubs/backends.dart` replaces this
/// file in the DartPad preview, where plugins aren't available.
class Backends {
  const Backends({
    required this.store,
    required this.purchases,
    required this.share,
    required this.reminders,
    required this.sounds,
    required this.accounts,
  });

  final KeyValueStore store;
  final PurchaseService purchases;
  final ShareService share;
  final ReminderService reminders;
  final SoundService sounds;
  final AccountService accounts;

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
      sounds: _AudioSoundService(),
      accounts: storeSupported ? await _FirebaseAccountService.create() : FakeAccountService(supported: false),
    );
  }
}

/// The Firebase project, passed in at build time (see docs/FIREBASE_SETUP.md):
/// `--dart-define=FIREBASE_API_KEY=… --dart-define=FIREBASE_PROJECT_ID=…` and
/// so on. A build without them simply has no sign-in.
class _FirebaseConfig {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  /// The *Web client* OAuth id from Firebase: Android sign-in needs it.
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// The iOS OAuth client id (iOS only).
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static String get appId => _ios ? iosAppId : androidAppId;

  static bool get complete =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      senderId.isNotEmpty &&
      appId.isNotEmpty &&
      webClientId.isNotEmpty &&
      (!_ios || iosClientId.isNotEmpty);

  static FirebaseOptions get options => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
        storageBucket: '$projectId.appspot.com',
        iosBundleId: _ios ? 'com.khemkaran.chance' : null,
        iosClientId: _ios ? iosClientId : null,
      );
}

/// Google sign-in through Firebase Auth; progress in Firestore at
/// `users/{uid}` (see firestore.rules).
class _FirebaseAccountService implements AccountService {
  _FirebaseAccountService._();

  /// Connects to Firebase, or returns an unsupported service when this build
  /// has no Firebase config or the connection fails, so the app never breaks.
  static Future<AccountService> create() async {
    if (!_FirebaseConfig.complete) return FakeAccountService(supported: false);
    try {
      await Firebase.initializeApp(options: _FirebaseConfig.options);
      await GoogleSignIn.instance.initialize(
        serverClientId: _FirebaseConfig.webClientId,
        clientId: _FirebaseConfig._ios ? _FirebaseConfig.iosClientId : null,
      );
      // Wait for the saved session to be restored.
      await FirebaseAuth.instance.authStateChanges().first.timeout(const Duration(seconds: 3), onTimeout: () => null);
      return _FirebaseAccountService._();
    } on Object catch (e) {
      debugPrint('Accounts unavailable: $e');
      return FakeAccountService(supported: false);
    }
  }

  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => FirebaseFirestore.instance.collection('users').doc(uid);

  @override
  bool get supported => true;

  @override
  AccountUser? get user {
    final u = _auth.currentUser;
    return u == null ? null : AccountUser(uid: u.uid, name: u.displayName, email: u.email, photoUrl: u.photoURL);
  }

  /// Google's account picker, then a Firebase credential from its token.
  Future<UserCredential?> _googleCredential({bool reauthenticate = false}) async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AccountException('Google didn\'t return a sign-in token. Please try again.');
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return reauthenticate
          ? await _auth.currentUser!.reauthenticateWithCredential(credential)
          : await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AccountException('Google sign-in failed (${e.code.name}). Check your connection and try again.');
    } on FirebaseAuthException catch (e) {
      throw AccountException('Sign-in failed (${e.code}). Please try again.');
    }
  }

  @override
  Future<AccountUser?> signInWithGoogle() async {
    final result = await _googleCredential();
    return result == null ? null : user;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } on Object catch (e) {
      debugPrint('Google sign-out: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final current = _auth.currentUser;
    if (current == null) return;
    try {
      // The data goes first: once the account is gone, the rules no longer
      // let anyone delete it.
      await _doc(current.uid).delete();
      try {
        await current.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        // Deleting needs a fresh sign-in: ask Google once more.
        if (await _googleCredential(reauthenticate: true) == null) {
          throw const AccountException('Account not deleted: sign-in was cancelled.');
        }
        await _auth.currentUser!.delete();
      }
      await GoogleSignIn.instance.disconnect();
    } on AccountException {
      rethrow;
    } on Object catch (e) {
      throw AccountException('Couldn\'t delete the account: $e');
    }
  }

  @override
  Future<Map<String, String>?> loadProgress() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _doc(uid).get();
    final progress = snap.data()?['progress'];
    if (progress is! Map) return null;
    return {for (final e in progress.entries) '${e.key}': '${e.value}'};
  }

  @override
  Future<void> saveProgress(Map<String, String> progress) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _doc(uid).set({'progress': progress, 'updatedAt': FieldValue.serverTimestamp()});
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

/// Sound effects via `audioplayers`: low-latency, mixed with the user's
/// music rather than pausing it, and silent when the phone is on mute.
class _AudioSoundService implements SoundService {
  final _players = <Sfx, AudioPlayer>{};
  Future<void>? _ready;

  Future<void> _init() => _ready ??= AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build(),
      );

  @override
  Future<void> play(Sfx sfx) async {
    try {
      await _init();
      var player = _players[sfx];
      if (player == null) {
        player = _players[sfx] = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
      }
      await player.stop();
      await player.play(AssetSource('sounds/${sfx.name}.wav'), volume: 0.7);
    } on Object catch (e) {
      debugPrint('Sound not played: $e');
    }
  }
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
