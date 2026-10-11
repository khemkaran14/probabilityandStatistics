import 'package:flutter/material.dart';

import 'package:chance/screens/home_screen.dart';
import 'package:chance/theme/app_theme.dart';

void main() => runApp(const ChanceApp());

class ChanceApp extends StatelessWidget {
  const ChanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chance',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
