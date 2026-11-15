import 'package:flutter/material.dart';

import 'package:chance/services/account_service.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

/// Signs in with Google and tells the learner how it went.
/// Returns true when they are signed in afterwards.
Future<bool> signInWithFeedback(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final state = AppScope.read(context);
  String message;
  var ok = false;
  try {
    ok = await state.signIn();
    message = ok ? 'Signed in. Your progress is saved to your account.' : 'Sign-in cancelled.';
  } on AccountException catch (e) {
    message = e.message;
  }
  messenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));
  return ok;
}

/// Settings card: sign in, or who is signed in with sign-out and delete.
class AccountCard extends StatefulWidget {
  const AccountCard({super.key});

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text('This permanently deletes your account and the progress saved in it. '
            'Progress on this phone stays until you reset it. Your purchase is kept by the store.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final state = AppScope.read(context);
    await _run(() async {
      try {
        await state.deleteAccount();
        messenger.showSnackBar(
          const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Your account has been deleted.')),
        );
      } on AccountException catch (e) {
        messenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.message)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final user = s.user;
    if (user == null) {
      return SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud_sync_rounded, color: AppColors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Keep your progress safe', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to save your XP, streak and lessons to your account and get them back on any phone.',
              style: TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                key: const ValueKey('google-sign-in'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                onPressed: _busy ? null : () => _run(() => signInWithFeedback(context)),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.login_rounded),
                label: const Text('Sign in with Google'),
              ),
            ),
          ],
        ),
      );
    }

    final name = (user.name?.trim().isNotEmpty ?? false) ? user.name!.trim() : (user.email ?? 'Signed in');
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.violet,
              foregroundColor: Colors.white,
              child: Text(name.characters.first.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              [
                if (user.email != null && user.email != name) user.email!,
                s.syncing ? 'Syncing…' : 'Progress saved to your account',
              ].join('\n'),
            ),
            isThreeLine: user.email != null && user.email != name,
          ),
          ListTile(
            key: const ValueKey('sign-out'),
            leading: const Icon(Icons.logout_rounded, color: AppColors.blue),
            title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Progress stays on this phone'),
            enabled: !_busy,
            onTap: () => _run(s.signOut),
          ),
          ListTile(
            key: const ValueKey('delete-account'),
            leading: const Icon(Icons.person_remove_rounded, color: AppColors.pink),
            title: const Text('Delete account', style: TextStyle(fontWeight: FontWeight.w800)),
            enabled: !_busy,
            onTap: _confirmDelete,
          ),
        ],
      ),
    );
  }
}
