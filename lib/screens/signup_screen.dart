import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
import '../widgets/auth_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  String? _errorMessage;
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });

    if (error == null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AuthShell(
      title: 'Create your account',
      subtitle:
          'Start with read-only access. An administrator can promote your role later.',
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password (6+ characters)',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: _showPassword ? 'Hide password' : 'Show password',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) {
            if (!_isLoading) _handleSignup();
          },
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: _isLoading ? null : _handleSignup,
          icon: _isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_alt_1_rounded),
          label: Text(_isLoading ? 'Creating account...' : 'Create account'),
        ),
      ],
    );
  }
}
