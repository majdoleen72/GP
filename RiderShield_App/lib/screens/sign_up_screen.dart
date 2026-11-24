
import 'dart:ui';
import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../navigation/ride_route.dart';
import '../widgets/action_button.dart';
import '../widgets/auth_layout.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/social_auth_options.dart';
import '../utils/validators.dart';

import 'sign_in_screen.dart';
import 'dashboard_shell.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();

  bool canSubmit = false;

  @override
  void initState() {
    super.initState();

    name.addListener(updateFormStatus);
    email.addListener(updateFormStatus);
    password.addListener(updateFormStatus);
    confirmation.addListener(updateFormStatus);
  }

  String? checkName(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Full name is required';
    }

    if (text.length < 2) {
      return 'Enter at least 2 characters';
    }

    return null;
  }

  String? checkPassword(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Password is required';
    }

    if (text.length < 8) {
      return 'Use at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(text)) {
      return 'Add an uppercase letter (A-Z)';
    }

    if (!RegExp(r'[a-z]').hasMatch(text)) {
      return 'Add a lowercase letter (a-z)';
    }

    if (!RegExp(r'[0-9]').hasMatch(text)) {
      return 'Add at least one number';
    }

    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(text)) {
      return 'Add at least one special character';
    }

    return null;
  }

  String? checkConfirmation(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Please confirm your password';
    }

    if (text != password.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  void updateFormStatus() {
    if (!mounted) return;

    final valid =
        checkName(name.text) == null &&
        validateEmail(email.text) == null &&
        checkPassword(password.text) == null &&
        checkConfirmation(confirmation.text) == null;

    if (canSubmit != valid) {
      setState(() {
        canSubmit = valid;
      });
    }
  }

  void submit() {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!canSubmit) {
      return;
    }

    FocusScope.of(context).unfocus();

    // Current local account flow.
    RiderScope.of(context).setLoginDetails(
      name: name.text.trim(),
      emailAddress: email.text.trim(),
    );

    Navigator.of(context).pushAndRemoveUntil(
      rideRoute(const DashboardShell()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    name.removeListener(updateFormStatus);
    email.removeListener(updateFormStatus);
    password.removeListener(updateFormStatus);
    confirmation.removeListener(updateFormStatus);

    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Create account',
      subtitle: 'Smart protection starts right here.',
      switchPrompt: 'Already have an account?',
      switchAction: 'Sign in',
      onSwitch: () {
        Navigator.of(context).pushReplacement(
          rideRoute(const SignInScreen()),
        );
      },
      form: Form(
        key: formKey,
        autovalidateMode:
            AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // FULL NAME
              GlassAuthField(
                controller: name,
                hint: 'Full name',
                keyboardType: TextInputType.name,
                textCapitalization:
                    TextCapitalization.words,
                autofillHints: const [
                  AutofillHints.name,
                ],
                validator: checkName,
              ),

              const SizedBox(height: 10),

              // EMAIL
              GlassAuthField(
                controller: email,
                hint: 'Email address',
                keyboardType:
                    TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.email,
                ],
                validator: validateEmail,
              ),

              const SizedBox(height: 10),

              // PASSWORD
              GlassAuthField(
                controller: password,
                hint: 'Password',
                isPassword: true,
                autofillHints: const [
                  AutofillHints.newPassword,
                ],
                validator: checkPassword,
              ),

              const SizedBox(height: 10),

              // CONFIRM PASSWORD
              GlassAuthField(
                controller: confirmation,
                hint: 'Confirm password',
                isPassword: true,
                textInputAction:
                    TextInputAction.done,
                autofillHints: const [
                  AutofillHints.newPassword,
                ],
                validator: checkConfirmation,
                onSubmitted: submit,
              ),

              const SizedBox(height: 10),

              // PASSWORD REQUIREMENTS
              const PasswordRequirements(),

              const SizedBox(height: 12),

              // PASSWORD STRENGTH
              PasswordStrengthIndicator(
                controller: password,
              ),

              const SizedBox(height: 20),

              // CREATE ACCOUNT
              Opacity(
                opacity: canSubmit ? 1.0 : 0.5,
                child: ActionButton(
                  label: 'Create account',
                  onPressed: submit,
                  height: 50,
                ),
              ),

              const SizedBox(height: 18),

              // GOOGLE ONLY
              const SocialAuthOptions(
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------
// PASSWORD REQUIREMENTS - SIMPLE TEXT
// ---------------------------------------------

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password requirements',
          style: TextStyle(
            color: Color(0xFFAABCCD),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: 5),

        Text(
          '8+ characters  •  Uppercase  •  Lowercase  •  Number  •  Symbol',
          softWrap: true,
          style: TextStyle(
            color: Color(0xFF9FB2C5),
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------
// GLASS AUTH FIELD WITH LIVE VALIDATION
// ---------------------------------------------

class GlassAuthField extends StatefulWidget {
  const GlassAuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization =
        TextCapitalization.none,
    this.autofillHints,
    this.validator,
    this.isPassword = false,
    this.textInputAction =
        TextInputAction.next,
    this.onSubmitted,
    this.autovalidateMode =
        AutovalidateMode.onUserInteraction,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final AutovalidateMode autovalidateMode;

  @override
  State<GlassAuthField> createState() =>
      _GlassAuthFieldState();
}

class _GlassAuthFieldState
    extends State<GlassAuthField> {
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textCapitalization:
              widget.textCapitalization,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          autovalidateMode:
              widget.autovalidateMode,
          textInputAction:
              widget.textInputAction,
          obscureText:
              widget.isPassword && !visible,
          autocorrect: !widget.isPassword,
          enableSuggestions:
              !widget.isPassword,
          cursorColor:
              const Color(0xFFBDE5FF),

          onFieldSubmitted: (_) {
            if (widget.onSubmitted != null) {
              widget.onSubmitted!();
            } else {
              FocusScope.of(context).nextFocus();
            }
          },

          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),

          decoration: InputDecoration(
            hintText: widget.hint,

            hintStyle: const TextStyle(
              color: Color(0xFFD0DFEA),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),

            filled: true,
            fillColor:
                const Color(0x66536F82),

            isDense: true,

            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            suffixIcon: widget.isPassword
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        visible = !visible;
                      });
                    },
                    icon: Icon(
                      visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color:
                          const Color(0xFFD0DFEA),
                      size: 20,
                    ),
                  )
                : null,

            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: Color(0x44FFFFFF),
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: Color(0x44FFFFFF),
                width: 0.8,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: Color(0xFFBDE5FF),
                width: 1.4,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: Color(0xFFFF6B6B),
                width: 1.2,
              ),
            ),

            focusedErrorBorder:
                OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: Color(0xFFFF6B6B),
                width: 1.5,
              ),
            ),

            errorStyle: const TextStyle(
              color: Color(0xFFFF8A8A),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
