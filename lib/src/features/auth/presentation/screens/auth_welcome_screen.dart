import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_layout.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(title: "Let's get started"),
        const SizedBox(height: 48),
        FilledButton.icon(
          onPressed: () => context.push('/login/email'),
          icon: const Icon(Icons.mail_outline_rounded, size: 20),
          label: const Text('Continue with Email'),
        ),
      ],
    ),
  );
}
