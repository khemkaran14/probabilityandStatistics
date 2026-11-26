import 'package:flutter/material.dart';

import 'package:chance/theme/app_theme.dart';

/// The learner's photo, or their initial on a coloured circle while the
/// photo loads or if there is none.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.photoUrl, this.radius = 20});

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final url = photoUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.violet,
      foregroundColor: Colors.white,
      foregroundImage: url == null ? null : NetworkImage(url),
      onForegroundImageError: url == null ? null : (_, __) {},
      child: Text(initial, style: TextStyle(fontWeight: FontWeight.w900, fontSize: radius * 0.85)),
    );
  }
}
