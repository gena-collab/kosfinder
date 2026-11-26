import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RegisterForm();
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
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
      appBar: AppBar(title: const Text('Registrasi Pemilik')),
      body: Consumer<AuthProvider>(
        builder: (context, provider, child) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('register-email-field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('register-password-field'),
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => _submit(provider),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('register-submit-button'),
                    onPressed: provider.isLoading
                        ? null
                        : () => _submit(provider),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Daftar'),
                  ),
                  if (provider.errorMessage case final message?) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      key: const Key('register-error-message'),
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
                      key: const Key('register-success-message'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  TextButton(
                    key: const Key('register-login-link'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Sudah punya akun? Kembali ke login'),
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
    return provider.register(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }
}
