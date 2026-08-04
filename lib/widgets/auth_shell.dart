import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'theme_toggle_button.dart';

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.75),
              Theme.of(context).scaffoldBackgroundColor,
              colors.tertiaryContainer.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 8, right: 12, child: ThemeToggleButton()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.security_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'VULNERA',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppTheme.cyan,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.4,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 28),
                            ...children,
                            if (footer != null) ...[
                              const SizedBox(height: 10),
                              footer!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
