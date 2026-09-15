import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../services/firebase_state.dart';
import '../services/token_storage.dart';
import '../theme.dart';
import '../utils/errors.dart';
import '../widgets/widgets.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _emailMode = false;
  bool _loading = false;
  String? _error;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!firebaseReady) {
      setState(() => _error = 'Phone login is not available right now.');
      return;
    }
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      setState(() => _error = 'Enter your phone number');
      return;
    }
    final phone = '+91$digits';

    setState(() {
      _loading = true;
      _error = null;
    });

    // Create the reCAPTCHA verifier explicitly so it's always cleared below, even on
    // failure: the implicit verifier signInWithPhoneNumber(phone) would create on its
    // own is only cleared on success, leaving a stale widget that breaks the next attempt.
    RecaptchaVerifier? verifier;
    try {
      verifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instanceFor(app: FirebaseAuth.instance.app, pluginConstants: const {}),
      );
      final confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(phone, verifier);
      if (!mounted) return;
      context.push('/otp', extra: OtpArgs(confirmationResult: confirmationResult, phone: phone));
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      verifier?.clear();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _emailLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await Api.post('/auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
      if (res.statusCode != 200) {
        setState(() => _error = 'Incorrect email or password.');
        return;
      }
      final body = Api.decode(res);
      await TokenStorage.save(body['access_token'], body['role']);
      if (!mounted) return;
      context.go('/${body['role']}');
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _LoginForm(
            emailMode: _emailMode,
            loading: _loading,
            error: _error,
            phoneController: _phoneController,
            emailController: _emailController,
            passwordController: _passwordController,
            onSendOtp: _sendOtp,
            onEmailLogin: _emailLogin,
            onToggleMode: () => setState(() {
              _emailMode = !_emailMode;
              _error = null;
            }),
          );

          if (!wide) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.xl),
                child: form,
              ),
            );
          }

          return Row(
            children: [
              Expanded(child: _BrandPanel()),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(padding: const EdgeInsets.all(Spacing.xxl), child: form),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.primary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: Colors.white, borderRadius: AppRadius.md),
              child: Icon(Icons.auto_stories_rounded, size: 52, color: colorScheme.primary),
            ),
            const SizedBox(height: Spacing.xl),
            const Text(
              'Rural Edu Platform',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Learn anywhere, even offline',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final bool emailMode;
  final bool loading;
  final String? error;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSendOtp;
  final VoidCallback onEmailLogin;
  final VoidCallback onToggleMode;

  const _LoginForm({
    required this.emailMode,
    required this.loading,
    required this.error,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.onSendOtp,
    required this.onEmailLogin,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Welcome 👋', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: Spacing.xs),
        Text(
          emailMode ? 'Log in with your email to continue.' : 'Log in with your phone number to start learning.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: Spacing.xxl),
        if (!emailMode) ...[
          AppTextField(
            label: 'Phone number',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            prefixText: '+91  ',
          ),
          const SizedBox(height: Spacing.lg),
          PrimaryButton(label: 'Send OTP', onPressed: onSendOtp, loading: loading),
        ] else ...[
          AppTextField(label: 'Email', controller: emailController, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: Spacing.md),
          AppTextField(label: 'Password', controller: passwordController, obscureText: true),
          const SizedBox(height: Spacing.lg),
          PrimaryButton(label: 'Login', onPressed: onEmailLogin, loading: loading),
        ],
        if (error != null) ...[
          const SizedBox(height: Spacing.md),
          Text(error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: Spacing.lg),
        Center(
          child: TextButton(
            onPressed: onToggleMode,
            child: Text(emailMode ? 'Login with phone (students)' : 'Login with email (teacher/admin)'),
          ),
        ),
      ],
    );
  }
}
