
import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../navigation/ride_route.dart';
import '../widgets/action_button.dart';
import '../widgets/auth_layout.dart';
import '../widgets/social_auth_options.dart';
import '../utils/validators.dart';

import 'sign_up_screen.dart';
import 'dashboard_shell.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void submit() {
    if (formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      RiderScope.of(context).setLoginDetails(
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
      title: 'Welcome back.',
      subtitle: 'Sign in and get ready for a safer ride.',
      switchPrompt: 'New to RiderShield?',
      switchAction: 'Create account',

      onSwitch: () {
        Navigator.of(context).pushReplacement(
          rideRoute(const SignUpScreen()),
        );
      },

      form: Form(
        key: formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassAuthField(
                controller: email,
                hint: 'Email address',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.email,
                ],
                validator: validateEmail,
              ),

              const SizedBox(height: 10),

              GlassAuthField(
                controller: password,
                hint: 'Password',
                isPassword: true,
                autofillHints: const [
                  AutofillHints.password,
                ],
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Enter your password';
                  }
                  return null;
                },
                onSubmitted: submit,
              ),

              const SizedBox(height: 20),

              ActionButton(
                label: 'Sign in',
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
