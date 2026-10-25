
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

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  void submit() {
    if (formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      RiderScope.of(context).setLoginDetails(
        name: name.text.trim(),
        emailAddress: email.text.trim(),
      );

      Navigator.of(context).pushAndRemoveUntil(
        rideRoute(const DashboardShell()),
        (route) => false,
      );
    }
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
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassAuthField(
                controller: name,
                hint: 'Full name',
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: (value) {
                  if ((value ?? '').trim().length < 2) {
                    return 'Enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              GlassAuthField(
                controller: email,
                hint: 'Email address',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
              ),

              const SizedBox(height: 10),

              GlassAuthField(
                controller: password,
                hint: 'Password',
                isPassword: true,
                autofillHints: const [
                  AutofillHints.newPassword,
                ],
                validator: validatePassword,
              ),

              const SizedBox(height: 10),

              GlassAuthField(
                controller: confirmation,
                hint: 'Confirm password',
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [
                  AutofillHints.newPassword,
                ],
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Confirm your password';
                  }

                  if (value != password.text) {
                    return 'Passwords do not match';
                  }

                  return null;
                },
                onSubmitted: submit,
              ),

              const SizedBox(height: 12),

              PasswordStrengthIndicator(
                controller: password,
              ),

              const SizedBox(height: 20),

              ActionButton(
                label: 'Create account',
                onPressed: submit,
                height: 50,
              ),

              const SizedBox(height: 18),

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

class GlassAuthField extends StatefulWidget {
  const GlassAuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.validator,
    this.isPassword = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
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

  @override
  State<GlassAuthField> createState() => _GlassAuthFieldState();
}

class _GlassAuthFieldState extends State<GlassAuthField> {
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
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          obscureText: widget.isPassword && !visible,
          autocorrect: !widget.isPassword,
          enableSuggestions: !widget.isPassword,
          cursorColor: const Color(0xFFBDE5FF),

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
            fillColor: const Color(0x66536F82),

            isDense: true,

            contentPadding: const EdgeInsets.symmetric(
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
                      color: const Color(0xFFD0DFEA),
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
                color: Color(0xFFFF9A9A),
              ),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: Color(0xFFFF9A9A),
                width: 1.4,
              ),
            ),

            errorStyle: const TextStyle(
              color: Color(0xFFFFB5B5),
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
