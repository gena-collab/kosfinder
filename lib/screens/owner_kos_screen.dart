import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kos.dart';
import '../providers/auth_provider.dart';
import '../providers/kos_provider.dart';
import '../repositories/kos_repository.dart';
import 'login_screen.dart';

class OwnerKosScreen extends StatefulWidget {
  const OwnerKosScreen({super.key, required this.repository});

  final KosRepository repository;

  @override
  State<OwnerKosScreen> createState() => _OwnerKosScreenState();
}

class _OwnerKosScreenState extends State<OwnerKosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.read<AuthProvider>().isAuthenticated) {
        _openLogin();
      }
    });
  }

  void _openLogin() {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, bool>(
      selector: (_, provider) => provider.isAuthenticated,
      builder: (context, isAuthenticated, child) {
        if (!isAuthenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pengelolaan Kos')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Login diperlukan untuk mengelola kos.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _openLogin,
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ChangeNotifierProvider(
          create: (_) => OwnerKosProvider(widget.repository)..loadOwnerKos(),
          child: const _OwnerKosContent(),
        );
      },
    );
  }
}

class _OwnerKosContent extends StatelessWidget {
  const _OwnerKosContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengelolaan Kos')),
      body: Consumer<OwnerKosProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final errorMessage = provider.errorMessage;
          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: provider.loadOwnerKos,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.kosList.isEmpty) {
            return const Center(child: Text('Anda belum memiliki kos.'));
          }

          return Column(
            children: [
              if (provider.deleteErrorMessage case final message?)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    message,
                    key: const Key('owner-delete-error-message'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.kosList.length,
                  itemBuilder: (context, index) {
                    final kos = provider.kosList[index];
                    return ListTile(
                      key: Key('owner-kos-${kos.id}'),
                      title: Text(kos.nama),
                      subtitle: Text(_formatPrice(kos.hargaBulanan)),
                      trailing: provider.deletingKosId == kos.id
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              key: Key('delete-kos-${kos.id}'),
                              tooltip: 'Hapus kos',
                              onPressed: provider.deletingKosId == null
                                  ? () => _confirmDelete(context, provider, kos)
                                  : null,
                              icon: const Icon(Icons.delete_outline),
                            ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OwnerKosProvider provider,
    Kos kos,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus kos?'),
        content: Text('Hapus "${kos.nama}" secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final deleted = await provider.deleteKos(kos.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kos berhasil dihapus.')));
    }
  }

  String _formatPrice(double price) {
    final decimalPlaces = price == price.truncateToDouble() ? 0 : 2;
    return 'Rp ${price.toStringAsFixed(decimalPlaces)}';
  }
}
