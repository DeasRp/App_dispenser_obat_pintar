class RiwayatStokModel {
  final int persen;
  final DateTime createdAt;

  RiwayatStokModel({required this.persen, required this.createdAt});

  factory RiwayatStokModel.fromJson(Map<String, dynamic> json) {
    return RiwayatStokModel(
      persen: json['persen'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Hasil agregasi jumlah pengambilan obat per hari, dipakai untuk
/// BarChart Frekuensi Pengambilan.
class FrekuensiHarianModel {
  final DateTime tanggal;
  final int jumlahDiambil;

  FrekuensiHarianModel({required this.tanggal, required this.jumlahDiambil});
}

/// Hasil agregasi persentase kepatuhan, dipakai untuk PieChart.
class KepatuhanModel {
  final int diambil;
  final int gagalVerifikasi;
  final int terlewat;

  KepatuhanModel({
    required this.diambil,
    required this.gagalVerifikasi,
    required this.terlewat,
  });

  int get total => diambil + gagalVerifikasi + terlewat;

  double get persenKepatuhan => total == 0 ? 0 : (diambil / total) * 100;
}

enum RentangWaktu { mingguan, bulanan }
