class JadwalObatModel {
  final String? id;
  final String lansiaId;
  final String jam;          // format "HH:mm:ss" atau "HH:mm"
  final String namaObat;
  final String jumlah;
  final int trackAudio;
  final int urutanKompartemen;
  final bool aktif;

  JadwalObatModel({
    this.id,
    required this.lansiaId,
    required this.jam,
    required this.namaObat,
    required this.jumlah,
    required this.trackAudio,
    required this.urutanKompartemen,
    this.aktif = true,
  });

  factory JadwalObatModel.fromJson(Map<String, dynamic> json) {
    return JadwalObatModel(
      id: json['id'] as String?,
      lansiaId: json['lansia_id'] as String,
      jam: (json['jam'] as String).substring(0, 5), // "08:00:00" -> "08:00"
      namaObat: json['nama_obat'] as String,
      jumlah: json['jumlah'] as String,
      trackAudio: json['track_audio'] as int,
      urutanKompartemen: json['urutan_kompartemen'] as int,
      aktif: json['aktif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lansia_id': lansiaId,
      'jam': jam,
      'nama_obat': namaObat,
      'jumlah': jumlah,
      'track_audio': trackAudio,
      'urutan_kompartemen': urutanKompartemen,
      'aktif': aktif,
    };
  }

  JadwalObatModel copyWith({
    String? jam,
    String? namaObat,
    String? jumlah,
    int? trackAudio,
    int? urutanKompartemen,
    bool? aktif,
  }) {
    return JadwalObatModel(
      id: id,
      lansiaId: lansiaId,
      jam: jam ?? this.jam,
      namaObat: namaObat ?? this.namaObat,
      jumlah: jumlah ?? this.jumlah,
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
  final DateTime waktuDiambil;
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
      waktuDiambil: DateTime.parse(json['waktu_diambil'] as String),
      status: json['status'] as String,
    );
  }
}
