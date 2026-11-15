import 'dart:convert';

import 'package:chance/services/account_service.dart';
import 'package:chance/services/key_value_store.dart';
import 'package:chance/state/progress_merge.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _me = AccountUser(uid: 'u1', name: 'Asha', email: 'asha@example.com');

void main() {
  group('mergeProgress', () {
    test('keeps everything either copy earned', () {
      final merged = mergeProgress(
        {
          'xp': '300',
          'completed': 'a,b',
          'perfect': 'a',
          'bestStreak': '4',
          'challengesDone': '2',
          'history': jsonEncode({'2026-03-01': 50, '2026-03-02': 20}),
        },
        {
          'xp': '250',
          'completed': 'b,c',
          'perfect': 'c',
          'bestStreak': '6',
          'challengesDone': '1',
          'history': jsonEncode({'2026-03-02': 40, '2026-03-03': 10}),
        },
      );
      expect(merged['xp'], '300');
      expect(merged['completed'], 'a,b,c');
      expect(merged['perfect'], 'a,c');
      expect(merged['bestStreak'], '6');
      expect(merged['challengesDone'], '2');
      expect(jsonDecode(merged['history']!), {'2026-03-01': 50, '2026-03-02': 40, '2026-03-03': 10});
    });

    test('the streak comes from the copy that was active most recently', () {
      final merged = mergeProgress(
        {'streak': '9', 'lastActive': '2026-03-01'},
        {'streak': '2', 'lastActive': '2026-03-05'},
      );
      expect((merged['streak'], merged['lastActive']), ('2', '2026-03-05'));
      final sameDay = mergeProgress(
        {'streak': '3', 'lastActive': '2026-03-05'},
        {'streak': '5', 'lastActive': '2026-03-05'},
      );
      expect(sameDay['streak'], '5');
    });

    test('copes with empty and corrupt copies', () {
      final merged = mergeProgress({}, {'history': 'not json', 'xp': 'x'});
      expect(merged['xp'], '0');
      expect(merged['completed'], '');
      expect(merged['streak'], '0');
      expect(jsonDecode(merged['history']!), isEmpty);
    });

    test('premium and settings never sync', () {
      expect(kSyncedKeys, isNot(contains('premium')));
      expect(kSyncedKeys, isNot(contains('dailyGoal')));
    });
  });

  group('signing in', () {
    test('merges this phone with the cloud, then keeps the cloud up to date', () async {
      final accounts = FakeAccountService(nextUser: _me);
      accounts.cloud['u1'] = {'xp': '500', 'completed': 'galton,coin_flips', 'premium': 'true'};
      final s = makeState(accounts: accounts);
      s.completeLesson('averages', correct: 3, total: 3);

      expect(await s.signIn(), isTrue);
      expect(s.user?.name, 'Asha');
      expect(s.xp, 500);
      expect(s.completed, containsAll(['galton', 'coin_flips', 'averages']));
      expect(s.premium, isFalse, reason: 'premium only comes from the store');

      s.completeLesson('spread', correct: 2, total: 3);
      await Future<void>.delayed(Duration.zero);
      expect(accounts.cloud['u1']!['completed'], contains('spread'));
      expect(accounts.cloud['u1']!['xp'], '${s.xp}');
    });

    test('a new phone gets its progress back on launch', () async {
      final accounts = FakeAccountService(nextUser: _me)..user = _me;
      accounts.cloud['u1'] = {'xp': '800', 'completed': 'galton', 'bestStreak': '7'};
      final s = makeState(store: MemoryStore(), accounts: accounts);
      await Future<void>.delayed(Duration.zero);
      expect((s.xp, s.bestStreak), (800, 7));
      expect(s.completed, {'galton'});
    });

    test('cancelling the picker changes nothing', () async {
      final accounts = FakeAccountService(nextUser: null);
      final s = makeState(accounts: accounts);
      expect(await s.signIn(), isFalse);
      expect(s.user, isNull);
      expect(accounts.cloud, isEmpty);
    });

    test('a failed sign-in reports why', () async {
      final s = makeState(accounts: FakeAccountService(failWith: const AccountException('No connection')));
      await expectLater(s.signIn(), throwsA(isA<AccountException>()));
      expect(s.user, isNull);
    });

    test('signing out keeps progress on the phone and stops uploads', () async {
      final accounts = FakeAccountService(nextUser: _me);
      final s = makeState(accounts: accounts);
      await s.signIn();
      s.completePractice(4);
      await s.signOut();
      final xp = s.xp;
      s.completePractice(4);
      await Future<void>.delayed(Duration.zero);
      expect(s.user, isNull);
      expect(accounts.cloud['u1']!['xp'], '$xp');
      expect(s.xp, greaterThan(xp));
    });

    test('deleting the account removes the cloud copy', () async {
      final accounts = FakeAccountService(nextUser: _me);
      final s = makeState(accounts: accounts);
      await s.signIn();
      s.completePractice(4);
      await s.deleteAccount();
      expect(accounts.cloud, isEmpty);
      expect(s.user, isNull);
      expect(s.xp, 20, reason: 'progress stays on this phone');
    });

    test('resetting progress resets the cloud copy too', () async {
      final accounts = FakeAccountService(nextUser: _me);
      final s = makeState(accounts: accounts);
      await s.signIn();
      s.completeLesson('galton', correct: 3, total: 3);
      s.resetProgress();
      await Future<void>.delayed(Duration.zero);
      expect(accounts.cloud['u1']!['xp'], '0');
      expect(accounts.cloud['u1']!['completed'], '');
    });

    test('builds without a cloud project never show an account', () {
      final s = makeState(accounts: FakeAccountService(supported: false)..user = _me);
      expect(s.user, isNull);
    });
  });
}
