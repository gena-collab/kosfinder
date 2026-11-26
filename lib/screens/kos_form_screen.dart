import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kos.dart';
import '../providers/kos_provider.dart';
import '../repositories/kos_repository.dart';

class KosFormScreen extends StatelessWidget {
  const KosFormScreen({super.key, required this.repository, this.kos});

  final KosRepository repository;
  final Kos? kos;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KosFormProvider(repository),
      child: _KosForm(kos: kos),
    );
  }
}

class _KosForm extends StatefulWidget {
  const _KosForm({this.kos});

  final Kos? kos;

  @override
  State<_KosForm> createState() => _KosFormState();
}

class _KosFormState extends State<_KosForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _hargaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _fasilitasController = TextEditingController();
  final _fotoUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final kos = widget.kos;
    if (kos == null) {
      return;
    }

    _namaController.text = kos.nama;
    _alamatController.text = kos.alamat;
    _hargaController.text = kos.hargaBulanan.toString();
    _deskripsiController.text = kos.deskripsi;
    _fasilitasController.text = kos.fasilitas ?? '';
    _fotoUrlController.text = kos.fotoUrl ?? '';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    _fasilitasController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kos == null ? 'Tambah Kos' : 'Edit Kos'),
      ),
      body: Consumer<KosFormProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  key: const Key('kos-form-name-field'),
                  controller: _namaController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nama Kos'),
                  validator: _requiredValidator,
                ),
                TextFormField(
                  key: const Key('kos-form-address-field'),
                  controller: _alamatController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  validator: _requiredValidator,
                ),
                TextFormField(
                  key: const Key('kos-form-price-field'),
                  controller: _hargaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Harga per Bulan',
                    prefixText: 'Rp ',
                  ),
                  validator: _priceValidator,
                ),
                TextFormField(
                  key: const Key('kos-form-description-field'),
                  controller: _deskripsiController,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  validator: _requiredValidator,
                ),
                TextFormField(
                  key: const Key('kos-form-facilities-field'),
                  controller: _fasilitasController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Fasilitas (opsional)',
                  ),
                ),
                TextFormField(
                  key: const Key('kos-form-photo-url-field'),
                  controller: _fotoUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'URL Foto (opsional)',
                  ),
                ),
                const SizedBox(height: 24),
                if (provider.errorMessage case final message?) ...[
                  Text(
                    message,
                    key: const Key('kos-form-error-message'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  key: const Key('kos-form-submit-button'),
                  onPressed: provider.isSaving ? null : () => _submit(provider),
                  child: provider.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.kos == null ? 'Simpan' : 'Simpan Perubahan',
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kolom ini wajib diisi.';
    }
    return null;
  }

  String? _priceValidator(String? value) {
    final price = double.tryParse(value?.trim() ?? '');
    if (price == null || !price.isFinite || price <= 0) {
      return 'Harga harus lebih dari 0.';
    }
    return null;
  }

  Future<void> _submit(KosFormProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final arguments = (
      nama: _namaController.text.trim(),
      alamat: _alamatController.text.trim(),
      hargaBulanan: double.parse(_hargaController.text.trim()),
      deskripsi: _deskripsiController.text.trim(),
      fasilitas: _optionalValue(_fasilitasController.text),
      fotoUrl: _optionalValue(_fotoUrlController.text),
    );
    final kos = widget.kos;
    final saved = kos == null
        ? await provider.saveKos(
            nama: arguments.nama,
            alamat: arguments.alamat,
            hargaBulanan: arguments.hargaBulanan,
            deskripsi: arguments.deskripsi,
            fasilitas: arguments.fasilitas,
            fotoUrl: arguments.fotoUrl,
          )
        : await provider.updateKos(
            id: kos.id,
            nama: arguments.nama,
            alamat: arguments.alamat,
            hargaBulanan: arguments.hargaBulanan,
            deskripsi: arguments.deskripsi,
            fasilitas: arguments.fasilitas,
            fotoUrl: arguments.fotoUrl,
          );
    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
