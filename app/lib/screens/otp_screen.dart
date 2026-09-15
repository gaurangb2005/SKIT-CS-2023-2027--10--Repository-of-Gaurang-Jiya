import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../services/token_storage.dart';
import '../theme.dart';
import '../utils/errors.dart';
import '../widgets/widgets.dart';

class OtpArgs {
  final ConfirmationResult confirmationResult;
  final String phone;

  OtpArgs({required this.confirmationResult, required this.phone});
}

class OtpScreen extends StatefulWidget {
  final OtpArgs args;

  const OtpScreen({super.key, required this.args});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late ConfirmationResult _confirmationResult;
  String _code = '';
  bool _loading = false;
  String? _error;
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _confirmationResult = widget.args.confirmationResult;
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    // Explicit verifier + guaranteed clear(), same reasoning as login_screen's _sendOtp:
    // an implicit verifier is only cleared on success and would otherwise leak on failure.
    RecaptchaVerifier? verifier;
    try {
      verifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instanceFor(app: FirebaseAuth.instance.app, pluginConstants: const {}),
      );
      _confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(widget.args.phone, verifier);
      _startResendTimer();
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      verifier?.clear();
    }
  }

  Future<void> _verify() async {
    if (_code.length != 6) {
      setState(() => _error = 'Enter the full 6-digit code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await _confirmationResult.confirm(_code);
      final idToken = await credential.user?.getIdToken();
      final res = await Api.post('/auth/otp-login', {'id_token': idToken});
      if (res.statusCode != 200) {
        setState(() => _error = 'Login failed. Please try again.');
        return;
      }
      final body = Api.decode(res);
      await TokenStorage.save(body['access_token'], body['role']);

      final me = await Api.get('/auth/me', token: body['access_token']);
      final meBody = Api.decode(me);

      if (!mounted) return;
      if (body['role'] == 'student' && meBody['name'] == 'Student') {
        context.go('/register');
      } else {
        context.go('/${body['role']}');
      }
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Verify OTP',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter the code', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: Spacing.xs),
          Text(
            'We sent a 6-digit code to ${widget.args.phone}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: Spacing.xxl),
          _OtpDigitBoxes(onChanged: (code) => setState(() => _code = code)),
          const SizedBox(height: Spacing.xl),
          PrimaryButton(label: 'Verify', onPressed: _verify, loading: _loading),
          if (_error != null) ...[
            const SizedBox(height: Spacing.md),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: Spacing.lg),
          Center(
            child: _secondsLeft > 0
                ? Text('Resend code in ${_secondsLeft}s', style: Theme.of(context).textTheme.bodyMedium)
                : TextButton(onPressed: _resend, child: const Text('Resend code')),
          ),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Change phone number'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Six auto-advancing digit boxes. No package: plain TextFields + FocusNodes.
class _OtpDigitBoxes extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _OtpDigitBoxes({required this.onChanged});

  @override
  State<_OtpDigitBoxes> createState() => _OtpDigitBoxesState();
}

class _OtpDigitBoxesState extends State<_OtpDigitBoxes> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _controllers.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      _focusNodes[digits.length.clamp(0, 5)].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace &&
                    _controllers[i].text.isEmpty &&
                    i > 0) {
                  _controllers[i - 1].clear();
                  _focusNodes[i - 1].requestFocus();
                  widget.onChanged(_controllers.map((c) => c.text).join());
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: AspectRatio(
                aspectRatio: 0.8,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: Theme.of(context).textTheme.titleLarge,
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (v) => _onChanged(i, v),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
