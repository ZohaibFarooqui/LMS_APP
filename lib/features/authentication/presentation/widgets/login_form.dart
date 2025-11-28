import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.usernameController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onLoginPressed,
    required this.isLoading,
    super.key,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onLoginPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Employee Code',
          controller: usernameController,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Password',
          controller: passwordController,
          obscureText: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: (value) => onRememberMeChanged(value ?? false),
            ),
            const Text('Remember Me'),
          ],
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Sign In',
          isLoading: isLoading,
          onPressed: onLoginPressed,
        ),
      ],
    );
  }
}

