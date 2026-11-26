import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/kos_provider.dart';
import '../repositories/kos_repository.dart';
import 'kos_detail_screen.dart';

class KosListScreen extends StatelessWidget {
  const KosListScreen({super.key, required this.repository});

  final KosRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KosProvider(repository)..loadKos(),
      child: _KosListView(repository: repository),
    );
  }
}

class _KosListView extends StatelessWidget {
  const _KosListView({required this.repository});

  final KosRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Kos')),
      body: Consumer<KosProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final errorMessage = provider.errorMessage;
          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(errorMessage, textAlign: TextAlign.center),
              ),
            );
          }

          if (provider.kosList.isEmpty) {
            return const Center(child: Text('Data kos tidak ditemukan.'));
          }

          return ListView.builder(
            itemCount: provider.kosList.length,
            itemBuilder: (context, index) {
              final kos = provider.kosList[index];
              return ListTile(
                title: Text(kos.nama),
                subtitle: Text(_formatPrice(kos.hargaBulanan)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => KosDetailScreen(
                        repository: repository,
                        kosId: kos.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatPrice(double price) {
    final decimalPlaces = price == price.truncateToDouble() ? 0 : 2;
    return 'Rp ${price.toStringAsFixed(decimalPlaces)}';
  }
}
