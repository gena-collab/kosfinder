import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kos.dart';
import '../providers/kos_provider.dart';
import '../repositories/kos_repository.dart';

class KosDetailScreen extends StatelessWidget {
  const KosDetailScreen({
    super.key,
    required this.repository,
    required this.kosId,
  });

  final KosRepository repository;
  final String kosId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KosDetailProvider(repository)..loadKosDetail(kosId),
      child: const _KosDetailView(),
    );
  }
}

class _KosDetailView extends StatelessWidget {
  const _KosDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kos')),
      body: Consumer<KosDetailProvider>(
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

          final kos = provider.kos;
          if (kos == null) {
            return const Center(child: Text('Data kos tidak ditemukan.'));
          }

          return _KosDetailContent(kos: kos);
        },
      ),
    );
  }
}

class _KosDetailContent extends StatelessWidget {
  const _KosDetailContent({required this.kos});

  final Kos kos;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _photo(),
        const SizedBox(height: 16),
        Text(kos.nama, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _detailField('Alamat', kos.alamat),
        _detailField('Harga per bulan', _formatPrice(kos.hargaBulanan)),
        _detailField('Deskripsi', kos.deskripsi),
        _detailField('Fasilitas', _optionalValue(kos.fasilitas)),
      ],
    );
  }

  Widget _photo() {
    final url = kos.fotoUrl?.trim();
    if (url == null || url.isEmpty) {
      return const Center(child: Text('Foto belum tersedia.'));
    }

    return Image.network(
      url,
      height: 220,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Text('Foto tidak dapat dimuat.')),
    );
  }

  Widget _detailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  String _optionalValue(String? value) {
    final content = value?.trim();
    return content == null || content.isEmpty ? 'Belum tersedia.' : content;
  }

  String _formatPrice(double price) {
    final decimalPlaces = price == price.truncateToDouble() ? 0 : 2;
    return 'Rp ${price.toStringAsFixed(decimalPlaces)}';
  }
}
