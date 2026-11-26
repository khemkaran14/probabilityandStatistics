import 'package:flutter/material.dart';

import 'package:chance/screens/profile_screen.dart';
import 'package:chance/services/account_service.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';
import 'package:chance/widgets/user_avatar.dart';

/// Signs in with Google and tells the learner if it was cancelled or
/// failed. With [announceSuccess] it also confirms a successful sign-in;
/// leave it off when the screen changes anyway, so the message doesn't
/// cover the next screen's buttons. Returns true when signed in.
Future<bool> signInWithFeedback(BuildContext context, {bool announceSuccess = false}) async {
  final messenger = ScaffoldMessenger.of(context);
  final state = AppScope.read(context);
  String? message;
  var ok = false;
  try {
    ok = await state.signIn();
    if (!ok) {
      message = 'Sign-in cancelled.';
    } else if (announceSuccess) {
      message = 'Signed in. Your progress is saved to your account.';
    }
  } on AccountException catch (e) {
    message = e.message;
  }
  if (message != null) {
    messenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));
  }
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
                onPressed: _busy ? null : () => _run(() => signInWithFeedback(context, announceSuccess: true)),
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

    final profile = s.profile;
    final name = profile?.name.isNotEmpty ?? false ? profile!.name : (user.name ?? user.email ?? 'Signed in');
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        key: const ValueKey('open-profile'),
        leading: UserAvatar(name: name, photoUrl: profile?.photoUrl ?? user.photoUrl),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          [
            if (user.email != null) user.email!,
            if (user.phone != null) user.phone!,
            if (s.syncing) 'Syncing…',
          ].join('\n'),
        ),
        isThreeLine: user.email != null && user.phone != null,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(ProfileScreen.route()),
      ),
    );
  }
}
