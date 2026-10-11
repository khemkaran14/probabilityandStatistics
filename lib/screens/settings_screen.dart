import 'package:flutter/material.dart';

import 'package:chance/screens/onboarding_screen.dart';
import 'package:chance/screens/paywall_screen.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

const String kAppVersion = '1.3.0';

const String kShareAppText = 'I\'m learning probability & statistics with Chance: '
    'short animated lessons that show why the formulas work. Try it!';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text('This clears your XP, streak, finished lessons and badges. '
            'Your purchase and settings are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) AppScope.read(context).resetProgress();
  }

  Future<void> _restore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await AppScope.read(context).restorePurchases();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(switch (outcome) {
          PurchaseOutcome.purchased || PurchaseOutcome.restored => 'Purchase restored.',
          PurchaseOutcome.unavailable => 'The store isn\'t available on this device.',
          _ => 'No purchase found to restore.',
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return SafeArea(
      child: PhoneWidth(
        child: ListView(
          key: const ValueKey('settings-list'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            const SectionLabel('Daily goal'),
            const SizedBox(height: 10),
            DailyGoalPicker(goal: s.dailyGoal, onChanged: s.setDailyGoal),
            const SizedBox(height: 14),
            const SectionLabel('Preferences'),
            const SizedBox(height: 10),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile(
                value: s.haptics,
                onChanged: s.setHaptics,
                activeThumbColor: AppColors.green,
                title: const Text('Vibration on answers', style: TextStyle(fontWeight: FontWeight.w800)),
                secondary: const Icon(Icons.vibration_rounded, color: AppColors.orange),
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('Full course'),
            const SizedBox(height: 10),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      s.premium ? Icons.verified_rounded : Icons.lock_open_rounded,
                      color: AppColors.violet,
                    ),
                    title: Text(
                      s.premium ? 'All lessons unlocked' : 'Unlock all lessons',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(s.premium ? 'Thank you for your support!' : 'One-time purchase'),
                    trailing: s.premium ? null : const Icon(Icons.chevron_right_rounded),
                    onTap: s.premium ? null : () => Navigator.of(context).push(PaywallScreen.route()),
                  ),
                  if (!s.premium)
                    ListTile(
                      leading: const Icon(Icons.restore_rounded, color: AppColors.blue),
                      title: const Text('Restore purchase', style: TextStyle(fontWeight: FontWeight.w800)),
                      onTap: () => _restore(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('About'),
            const SizedBox(height: 10),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.ios_share_rounded, color: AppColors.cyan),
                    title: const Text('Share Chance with a friend', style: TextStyle(fontWeight: FontWeight.w800)),
                    onTap: () => s.share.shareText(kShareAppText),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.pink),
                    title: const Text('Reset progress', style: TextStyle(fontWeight: FontWeight.w800)),
                    onTap: () => _confirmReset(context),
                  ),
                  const ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: AppColors.muted),
                    title: Text('Version $kAppVersion', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('No ads. No account. Your progress stays on this device.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
