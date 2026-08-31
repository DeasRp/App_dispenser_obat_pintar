class JadwalObatModel {
  final String? id;
  final String lansiaId;
  final String jam; // format "HH:mm:ss" atau "HH:mm"
  final String namaObat;
  final int jumlahAngka;
  final String satuan;
  final int trackAudio;
  final int urutanKompartemen;
  final bool aktif;

  JadwalObatModel({
    this.id,
    required this.lansiaId,
    required this.jam,
    required this.namaObat,
    required this.jumlahAngka,
    required this.satuan,
    required this.trackAudio,
    required this.urutanKompartemen,
    this.aktif = true,
  });

  String get jumlahLabel => '$jumlahAngka $satuan';

  factory JadwalObatModel.fromJson(Map<String, dynamic> json) {
    // Fallback untuk data lama yang masih memiliki kolom `jumlah`
    // seperti "1 tablet". Database hasil migrasi seharusnya sudah memiliki
    // `jumlah_angka` dan `satuan`.
    int jumlahAngka = json['jumlah_angka'] as int? ?? 1;
    String satuan = (json['satuan'] as String? ?? '').trim();

    if ((json['jumlah_angka'] == null || satuan.isEmpty) &&
        json['jumlah'] is String) {
      final jumlahLama = (json['jumlah'] as String).trim();
      final parts = jumlahLama.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        jumlahAngka = int.tryParse(parts.first) ?? jumlahAngka;
      }
      if (satuan.isEmpty && parts.length > 1) {
        satuan = parts.sublist(1).join(' ');
      }
    }

    if (satuan.isEmpty) satuan = 'tablet';

    final jamRaw = json['jam'] as String? ?? '00:00';

    return JadwalObatModel(
      id: json['id'] as String?,
      lansiaId: json['lansia_id'] as String,
      jam: jamRaw.length >= 5 ? jamRaw.substring(0, 5) : jamRaw,
      namaObat: json['nama_obat'] as String,
      jumlahAngka: jumlahAngka,
      satuan: satuan,
      trackAudio: json['track_audio'] as int? ?? 1,
      urutanKompartemen: json['urutan_kompartemen'] as int,
      aktif: json['aktif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lansia_id': lansiaId,
      'jam': jam,
      'nama_obat': namaObat,
      'jumlah_angka': jumlahAngka,
      'satuan': satuan,
      'track_audio': trackAudio,
      'urutan_kompartemen': urutanKompartemen,
      'aktif': aktif,
    };
  }

  JadwalObatModel copyWith({
    String? jam,
    String? namaObat,
    int? jumlahAngka,
    String? satuan,
    int? trackAudio,
    int? urutanKompartemen,
    bool? aktif,
  }) {
    return JadwalObatModel(
      id: id,
      lansiaId: lansiaId,
      jam: jam ?? this.jam,
      namaObat: namaObat ?? this.namaObat,
      jumlahAngka: jumlahAngka ?? this.jumlahAngka,
      satuan: satuan ?? this.satuan,
      trackAudio: trackAudio ?? this.trackAudio,
      urutanKompartemen: urutanKompartemen ?? this.urutanKompartemen,
      aktif: aktif ?? this.aktif,
    );
  }
}

class RiwayatKonsumsiModel {
  final String id;
  final String? jadwalId;
  final String namaObat;
  final DateTime tanggal;
  final DateTime? waktuDiambil;
  final String status; // 'diambil' | 'gagal_verifikasi' | 'terlewat'

  RiwayatKonsumsiModel({
    required this.id,
    this.jadwalId,
    required this.namaObat,
    required this.tanggal,
    required this.waktuDiambil,
    required this.status,
  });

  factory RiwayatKonsumsiModel.fromJson(Map<String, dynamic> json) {
    return RiwayatKonsumsiModel(
      id: json['id'] as String,
      jadwalId: json['jadwal_id'] as String?,
      namaObat: json['nama_obat'] as String,
      tanggal: DateTime.parse(json['tanggal'] as String),
      waktuDiambil: json['waktu_diambil'] != null
          ? DateTime.parse(json['waktu_diambil'] as String)
          : null,
      status: json['status'] as String,
    );
  }
}
