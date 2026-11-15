/// The signed-in learner.
class AccountUser {
  const AccountUser({required this.uid, this.name, this.email, this.photoUrl});

  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
}

/// Sign-in with Google and the learner's progress saved in the cloud, so it
/// follows them to a new phone.
abstract class AccountService {
  /// False when this build has no cloud project configured (or on web):
  /// the app then hides everything about accounts.
  bool get supported;

  /// The signed-in user, or null.
  AccountUser? get user;

  /// Shows Google's account picker. Returns null if the user cancels.
  /// Throws [AccountException] if sign-in fails.
  Future<AccountUser?> signInWithGoogle();

  Future<void> signOut();

  /// Deletes the cloud copy of the progress and the account itself.
  /// Throws [AccountException] if it fails.
  Future<void> deleteAccount();

  /// The progress saved in the cloud for [user], or null if there is none.
  Future<Map<String, String>?> loadProgress();

  /// Replaces the cloud copy of the progress for [user].
  Future<void> saveProgress(Map<String, String> progress);
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

  /// The fake cloud: progress per uid.
  final Map<String, Map<String, String>> cloud = {};

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
    user = null;
  }

  @override
  Future<Map<String, String>?> loadProgress() async => cloud[user?.uid];

  @override
  Future<void> saveProgress(Map<String, String> progress) async {
    if (user != null) cloud[user!.uid] = {...progress};
  }
}
