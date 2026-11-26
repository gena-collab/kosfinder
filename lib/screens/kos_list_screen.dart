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

class _KosListView extends StatefulWidget {
  const _KosListView({required this.repository});

  final KosRepository repository;

  @override
  State<_KosListView> createState() => _KosListViewState();
}

class _KosListViewState extends State<_KosListView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String? _priceInputError;

  @override
  void dispose() {
    _searchController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Kos')),
      body: Consumer<KosProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: TextField(
                  key: const Key('kos-search-field'),
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Cari nama atau alamat',
                    suffixIcon: IconButton(
                      tooltip: 'Cari',
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.searchKos(_searchController.text),
                      icon: const Icon(Icons.search),
                    ),
                  ),
                  onSubmitted: (query) {
                    if (!provider.isLoading) {
                      provider.searchKos(query);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('kos-max-price-field'),
                        controller: _maxPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Harga maksimum (Rp)',
                          hintText: 'Contoh: 1000000',
                          errorText: _priceInputError,
                        ),
                        onSubmitted: (_) => _applyMaxPriceFilter(provider),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Terapkan filter harga',
                      onPressed: provider.isLoading
                          ? null
                          : () => _applyMaxPriceFilter(provider),
                      icon: const Icon(Icons.filter_list),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildResults(context, provider)),
            ],
          );
        },
      ),
    );
  }

  void _applyMaxPriceFilter(KosProvider provider) {
    final input = _maxPriceController.text.trim();
    if (input.isEmpty) {
      setState(() => _priceInputError = null);
      provider.filterKosByMaxPrice(null);
      return;
    }

    final maxPrice = double.tryParse(input);
    if (maxPrice == null || !maxPrice.isFinite || maxPrice < 0) {
      setState(() {
        _priceInputError = 'Masukkan batas harga maksimum yang valid.';
      });
      return;
    }

    setState(() => _priceInputError = null);
    provider.filterKosByMaxPrice(maxPrice);
  }

  Widget _buildResults(BuildContext context, KosProvider provider) {
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
                  repository: widget.repository,
                  kosId: kos.id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatPrice(double price) {
    final decimalPlaces = price == price.truncateToDouble() ? 0 : 2;
    return 'Rp ${price.toStringAsFixed(decimalPlaces)}';
  }
}
