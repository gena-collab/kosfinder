class Kos {
  const Kos({
    required this.id,
    required this.ownerId,
    required this.nama,
    required this.alamat,
    required this.hargaBulanan,
    required this.deskripsi,
    required this.createdAt,
    this.fasilitas,
    this.fotoUrl,
  });

  final String id;
  final String ownerId;
  final String nama;
  final String alamat;
  final double hargaBulanan;
  final String deskripsi;
  final String? fasilitas;
  final String? fotoUrl;
  final DateTime createdAt;

  factory Kos.fromJson(Map<String, dynamic> json) {
    return Kos(
      id: _requiredString(json, 'id'),
      ownerId: _requiredString(json, 'owner_id'),
      nama: _requiredString(json, 'nama'),
      alamat: _requiredString(json, 'alamat'),
      hargaBulanan: _requiredNumber(json, 'harga_bulanan').toDouble(),
      deskripsi: _requiredString(json, 'deskripsi'),
      fasilitas: _optionalString(json, 'fasilitas'),
      fotoUrl: _optionalString(json, 'foto_url'),
      createdAt: DateTime.parse(_requiredString(json, 'created_at')),
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw FormatException('Kolom $key wajib berupa teks yang tidak kosong.');
  }

  static num _requiredNumber(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value;
    }
    throw FormatException('Kolom $key wajib berupa angka.');
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) {
      return value as String?;
    }
    throw FormatException('Kolom $key harus berupa teks atau null.');
  }
}
