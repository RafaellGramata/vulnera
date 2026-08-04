import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Use light theme' : 'Use dark theme',
      onPressed: () => themeController.toggle(context),
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}
