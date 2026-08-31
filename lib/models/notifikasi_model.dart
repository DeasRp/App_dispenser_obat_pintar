class NotifikasiModel {
  final String id;
  final String lansiaId;
  final String jenis;
  final String judul;
  final String pesan;
  final bool dibaca;
  final DateTime createdAt;

  const NotifikasiModel({
    required this.id,
    required this.lansiaId,
    required this.jenis,
    required this.judul,
    required this.pesan,
    required this.dibaca,
    required this.createdAt,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    final jenis = (json['jenis'] ?? json['tipe'] ?? json['type'] ?? 'info')
        .toString();

    final pesan = (json['pesan'] ??
            json['message'] ??
            json['keterangan'] ??
            json['deskripsi'] ??
            '')
        .toString();

    final rawCreatedAt = json['created_at'] ?? json['waktu'] ?? json['tanggal'];
    final createdAt = rawCreatedAt == null
        ? DateTime.now()
        : DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();

    return NotifikasiModel(
      id: (json['id'] ?? '').toString(),
      lansiaId: (json['lansia_id'] ?? '').toString(),
      jenis: jenis,
      judul: (json['judul'] ?? json['title'] ?? _judulDariJenis(jenis)).toString(),
      pesan: pesan,
      dibaca: json['dibaca'] == true || json['is_read'] == true || json['read'] == true,
      createdAt: createdAt,
    );
  }

  static String _judulDariJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'diambil':
      case 'obat_diambil':
      case 'berhasil':
        return 'Obat Berhasil Diambil';
      case 'terlambat':
      case 'telat':
        return 'Pengambilan Obat Terlambat';
      case 'terlewat':
        return 'Jadwal Obat Terlewat';
      case 'stok_rendah':
      case 'stok_menipis':
        return 'Stok Obat Hampir Habis';
      default:
        return 'Notifikasi Remindora';
    }
  }
}
