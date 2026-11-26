import 'package:flutter/material.dart';

import 'package:chance/screens/learn_screen.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/account_card.dart';
import 'package:chance/widgets/common.dart';

/// Shown after the welcome pages until the learner signs in with Google.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      await signInWithFeedback(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            children: [
              const Center(child: AppLogo(size: 72)),
              const SizedBox(height: 24),
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Create your '),
                    TextSpan(text: 'free', style: TextStyle(color: AppColors.pink)),
                    TextSpan(text: ' account'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: kDisplay.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to start learning. Your progress is saved to your account, so you never lose it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 28),
              const _Benefit(Icons.cloud_done_rounded, AppColors.blue, 'Progress saved on every phone'),
              const _Benefit(Icons.local_fire_department_rounded, AppColors.orange, 'Keep your streak and badges'),
              const _Benefit(Icons.school_rounded, AppColors.green, 'Chapters 1–3 free to start'),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  key: const ValueKey('required-sign-in'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _busy ? null : _signIn,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.login_rounded),
                  label: const Text('Continue with Google'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'By continuing you agree to our privacy policy at divyrs.com/chance/privacy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.color, this.text);
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
