import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_button.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    context.read<AuthBloc>().add(
          LoginRequested(
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
            rememberMe: _rememberMe,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.status == AuthStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
            if (state.rememberedUsername != null) {
              _usernameController.text = state.rememberedUsername!;
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your employee credentials',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  LoginForm(
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    rememberMe: _rememberMe,
                    onRememberMeChanged: (value) => setState(() => _rememberMe = value),
                    onLoginPressed: _onLogin,
                    isLoading: state.status == AuthStatus.loading,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: state.biometricEnabled,
                        onChanged: (value) => context.read<AuthBloc>().add(BiometricToggled(value)),
                      ),
                      const Text('Enable Biometric Login'),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: 12),
                  if (state.biometricEnabled && state.user != null)
                    AppButton(
                      label: 'Use Biometrics',
                      icon: Icons.fingerprint,
                      onPressed: () {
                        // Would trigger biometric auth using platform APIs.
                        if (_usernameController.text.isEmpty && state.user != null) {
                          _usernameController.text = state.user!.employeeCode;
                        }
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

