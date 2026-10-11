import 'package:flutter/material.dart';

import 'package:chance/screens/learn_screen.dart';
import 'package:chance/screens/practice_screen.dart';
import 'package:chance/screens/progress_screen.dart';
import 'package:chance/screens/settings_screen.dart';
import 'package:chance/theme/app_theme.dart';

/// Main app frame with bottom navigation between the four tabs.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  static const _tabs = [LearnScreen(), PracticeScreen(), ProgressScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.yellow,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school_rounded), label: 'Learn'),
          NavigationDestination(
              icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt_rounded), label: 'Practice'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Progress'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
