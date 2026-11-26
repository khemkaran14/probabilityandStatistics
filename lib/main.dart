import 'package:flutter/material.dart';

import 'package:chance/screens/onboarding_screen.dart';
import 'package:chance/screens/profile_screen.dart';
import 'package:chance/screens/shell_screen.dart';
import 'package:chance/screens/sign_in_screen.dart';
import 'package:chance/services/backends.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backends = await Backends.create();
  final state = AppState(
    store: backends.store,
    purchases: backends.purchases,
    share: backends.share,
    reminders: backends.reminders,
    sounds: backends.sounds,
    accounts: backends.accounts,
  );
  runApp(ChanceApp(state: state));
}

class ChanceApp extends StatelessWidget {
  const ChanceApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Chance',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _Root(),
      ),
    );
  }
}

/// Onboarding on first launch, then sign-in and the profile (when this build
/// has a cloud project), then the tabbed app.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: !s.onboarded
          ? const OnboardingScreen()
          : s.needsSignIn
              ? const SignInScreen()
              : s.needsProfile
                  ? const ProfileSetupScreen()
                  : const ShellScreen(),
    );
  }
}
