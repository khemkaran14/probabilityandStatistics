import 'dart:convert';

/// The signed-in learner, as the sign-in provider knows them.
class AccountUser {
  const AccountUser({required this.uid, this.name, this.email, this.photoUrl, this.phone});

  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;

  /// The mobile number verified by SMS, in international form (+91…).
  final String? phone;
}

/// What the learner tells us about themselves, saved with their account.
class UserProfile {
  const UserProfile({
    this.name = '',
    this.email,
    this.phone,
    this.photoUrl,
    this.marketingOptIn = false,
    this.consentAt,
  });

  final String name;
  final String? email;

  /// Verified mobile number (+91…). Only set after SMS verification.
  final String? phone;
  final String? photoUrl;

  /// Agreed to receive offers and updates.
  final bool marketingOptIn;

  /// When [marketingOptIn] was last changed (ISO 8601), as a consent record.
  final String? consentAt;

  /// Everything needed before the learner can use the app.
  bool get complete => name.trim().isNotEmpty && phone != null;

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    bool? marketingOptIn,
    String? consentAt,
  }) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        marketingOptIn: marketingOptIn ?? this.marketingOptIn,
        consentAt: consentAt ?? this.consentAt,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'marketingOptIn': marketingOptIn,
        'consentAt': consentAt,
      };

  static UserProfile fromMap(Map<Object?, Object?> m) => UserProfile(
        name: (m['name'] as String?) ?? '',
        email: m['email'] as String?,
        phone: m['phone'] as String?,
        photoUrl: m['photoUrl'] as String?,
        marketingOptIn: m['marketingOptIn'] == true,
        consentAt: m['consentAt'] as String?,
      );

  String encode() => jsonEncode(toMap());

  static UserProfile? decode(String? s) {
    if (s == null) return null;
    try {
      return fromMap(jsonDecode(s) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }
}

/// Turns what the learner typed into an international mobile number:
/// 10-digit Indian mobiles get +91; numbers starting with + are kept.
/// Returns null if it doesn't look like a mobile number.
String? normalizePhone(String input) {
  final digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
  if (RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(digits)) return digits;
  final local = digits.startsWith('0') ? digits.substring(1) : digits;
  if (RegExp(r'^[6-9]\d{9}$').hasMatch(local)) return '+91$local';
  if (RegExp(r'^91[6-9]\d{9}$').hasMatch(local)) return '+$local';
  return null;
}

/// Sign-in with Google, a profile with an SMS-verified mobile number and a
/// photo, and the learner's progress saved in the cloud.
abstract class AccountService {
  /// False when this build has no cloud project configured (or on web):
  /// the app then works without accounts.
  bool get supported;

  /// The signed-in user, or null.
  AccountUser? get user;

  /// Shows Google's account picker. Returns null if the user cancels.
  /// Throws [AccountException] if sign-in fails.
  Future<AccountUser?> signInWithGoogle();

  Future<void> signOut();

  /// Deletes the account, its profile, photo and progress.
  /// Throws [AccountException] if it fails.
  Future<void> deleteAccount();

  /// The progress saved in the cloud for [user], or null if there is none.
  Future<Map<String, String>?> loadProgress();

  /// Replaces the cloud copy of the progress for [user].
  Future<void> saveProgress(Map<String, String> progress);

  /// The profile saved for [user], or null if there is none yet.
  Future<UserProfile?> loadProfile();

  /// Saves the profile. Its phone must be the one verified for [user].
  Future<void> saveProfile(UserProfile profile);

  /// Sends an SMS code to [phone] (international form). Returns the id to
  /// pass to [confirmPhoneCode], or null if the phone verified itself
  /// automatically (Android can read the SMS). Throws [AccountException].
  Future<String?> sendPhoneCode(String phone);

  /// Checks the SMS [code] and attaches the number to the account.
  /// Throws [AccountException] on a wrong or expired code.
  Future<void> confirmPhoneCode(String verificationId, String code);

  /// Lets the learner pick a photo and uploads it. Returns its URL, or null
  /// if they cancelled. Throws [AccountException].
  Future<String?> pickAndUploadPhoto();
}

class AccountException implements Exception {
  const AccountException(this.message);

  /// A short, user-facing explanation.
  final String message;

  @override
  String toString() => message;
}

/// In-memory accounts and cloud. Used by tests and DartPad.
class FakeAccountService implements AccountService {
  FakeAccountService({this.supported = true, this.nextUser, this.failWith});

  @override
  final bool supported;

  /// Who "signs in" next; null means the user cancels the picker.
  AccountUser? nextUser;

  /// When set, sign-in throws this.
  AccountException? failWith;

  /// The SMS code that [confirmPhoneCode] accepts.
  static const smsCode = '123456';

  /// The fake cloud: progress and profiles per uid.
  final Map<String, Map<String, String>> cloud = {};
  final Map<String, UserProfile> profiles = {};

  /// Numbers SMS codes were sent to.
  final List<String> codesSentTo = [];

  /// What [pickAndUploadPhoto] returns (null = cancelled).
  String? nextPhotoUrl;

  @override
  AccountUser? user;

  @override
  Future<AccountUser?> signInWithGoogle() async {
    if (failWith != null) throw failWith!;
    return user = nextUser;
  }

  @override
  Future<void> signOut() async => user = null;

  @override
  Future<void> deleteAccount() async {
    cloud.remove(user?.uid);
    profiles.remove(user?.uid);
    user = null;
  }

  @override
  Future<Map<String, String>?> loadProgress() async => cloud[user?.uid];

  @override
  Future<void> saveProgress(Map<String, String> progress) async {
    if (user != null) cloud[user!.uid] = {...progress};
  }

  @override
  Future<UserProfile?> loadProfile() async => profiles[user?.uid];

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final u = user;
    if (u == null) throw const AccountException('Please sign in again.');
    if (profile.phone != u.phone) throw const AccountException('Please verify your mobile number.');
    profiles[u.uid] = profile;
  }

  String? _pendingPhone;

  @override
  Future<String?> sendPhoneCode(String phone) async {
    codesSentTo.add(phone);
    _pendingPhone = phone;
    return 'verification-1';
  }

  @override
  Future<void> confirmPhoneCode(String verificationId, String code) async {
    final u = user;
    if (u == null || _pendingPhone == null) throw const AccountException('Please send a new code.');
    if (code != smsCode) throw const AccountException('That code is not right. Check the SMS and try again.');
    user = AccountUser(uid: u.uid, name: u.name, email: u.email, photoUrl: u.photoUrl, phone: _pendingPhone);
  }

  @override
  Future<String?> pickAndUploadPhoto() async => nextPhotoUrl;
}
