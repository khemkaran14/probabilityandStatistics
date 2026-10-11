import 'package:flutter/material.dart';

import 'package:chance/screens/learn_screen.dart';
import 'package:chance/screens/practice_screen.dart';
import 'package:chance/screens/progress_screen.dart';
import 'package:chance/screens/settings_screen.dart';
import 'package:chance/theme/app_theme.dart';

/// Screens at least this wide (tablets, landscape) get a side rail instead
/// of the bottom bar.
const double kRailBreakpoint = 720;

/// Main app frame with navigation between the four tabs.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  static const _tabs = [LearnScreen(), PracticeScreen(), ProgressScreen(), SettingsScreen()];

  static const _items = [
    (Icons.school_outlined, Icons.school_rounded, 'Learn'),
    (Icons.bolt_outlined, Icons.bolt_rounded, 'Practice'),
    (Icons.insights_outlined, Icons.insights_rounded, 'Progress'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  void _select(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: _tab, children: _tabs);
    if (MediaQuery.sizeOf(context).width >= kRailBreakpoint) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: _tab,
                onDestinationSelected: _select,
                backgroundColor: AppColors.card,
                indicatorColor: AppColors.yellow,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.6,
                destinations: [
                  for (final (icon, selected, label) in _items)
                    NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.yellow,
        destinations: [
          for (final (icon, selected, label) in _items)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}
