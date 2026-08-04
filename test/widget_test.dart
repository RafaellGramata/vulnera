import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vulnera/theme/app_theme.dart';
import 'package:vulnera/theme/theme_controller.dart';
import 'package:vulnera/widgets/theme_toggle_button.dart';

void main() {
  tearDown(() => themeController.value = ThemeMode.system);

  testWidgets('light and dark themes expose the expected brightness', (
    tester,
  ) async {
    Brightness? brightness;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (context) {
            brightness = Theme.of(context).brightness;
            return const Scaffold();
          },
        ),
      ),
    );
    expect(brightness, Brightness.light);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            brightness = Theme.of(context).brightness;
            return const Scaffold();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(brightness, Brightness.dark);
  });

  testWidgets('theme toggle switches from light to dark', (tester) async {
    themeController.value = ThemeMode.light;

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController,
        builder: (context, mode, _) {
          return MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: const Scaffold(body: ThemeToggleButton()),
          );
        },
      ),
    );

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();

    expect(themeController.value, ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });
}
