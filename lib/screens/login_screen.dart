import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginForm();
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Pemilik')),
      body: Consumer<AuthProvider>(
        builder: (context, provider, child) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('login-email-field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('login-password-field'),
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => _submit(provider),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('login-submit-button'),
                    onPressed: provider.isLoading ? null : () => _submit(provider),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Masuk'),
                  ),
                  if (provider.errorMessage case final message?) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      key: const Key('login-error-message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (provider.successMessage case final message?) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      key: const Key('login-success-message'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (provider.isAuthenticated) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      key: const Key('login-continue-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Lanjutkan ke aplikasi'),
                    ),
                  ],
                  TextButton(
                    key: const Key('login-register-link'),
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(AuthProvider provider) {
    return provider.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }
}
