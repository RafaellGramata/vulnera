import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  void toggle(BuildContext context) {
    value = Theme.of(context).brightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }
}

final themeController = ThemeController();
