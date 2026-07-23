enum JadwalStatus {
  sudahDiambil,
  menunggu,
  terjadwal,
}

JadwalStatus parseJadwalStatus(String status) {
  switch (status.toLowerCase()) {
    case 'sudah_diambil':
      return JadwalStatus.sudahDiambil;
    case 'menunggu':
      return JadwalStatus.menunggu;
    case 'terjadwal':
      return JadwalStatus.terjadwal;
    default:
      return JadwalStatus.terjadwal;
  }
}

class JadwalItem {
  final String jam;
  final String namaObat;
  final JadwalStatus status;

  JadwalItem({
    required this.jam,
    required this.namaObat,
    required this.status,
  });

  factory JadwalItem.fromJson(Map<String, dynamic> json) {
    return JadwalItem(
      jam: json['time'] ?? json['jam'] ?? '',
      namaObat: json['obat'] ?? '',
      status: parseJadwalStatus(json['status'] ?? 'terjadwal'),
    );
  }
}

class DeviceStatus {
  final String namaLansia;
  final bool isDeviceOnline;
  final String wifiStatusText;
  final String nextScheduleTime;
  final String nextScheduleObat;
  final String nextScheduleJumlah;
  final int stokObatPercent;
  final bool statusGelasTerisi;
  final List<JadwalItem> todaySchedule;

  DeviceStatus({
    required this.namaLansia,
    required this.isDeviceOnline,
    required this.wifiStatusText,
    required this.nextScheduleTime,
    required this.nextScheduleObat,
    required this.nextScheduleJumlah,
    required this.stokObatPercent,
    required this.statusGelasTerisi,
    required this.todaySchedule,
  });

  factory DeviceStatus.initial() {
    return DeviceStatus(
      namaLansia: 'Lansia',
      isDeviceOnline: false,
      wifiStatusText: 'Tidak terhubung',
      nextScheduleTime: '--:--',
      nextScheduleObat: '-',
      nextScheduleJumlah: '-',
      stokObatPercent: 0,
      statusGelasTerisi: false,
      todaySchedule: [],
    );
  }

  DeviceStatus copyWith({
    String? namaLansia,
    bool? isDeviceOnline,
    String? wifiStatusText,
    String? nextScheduleTime,
    String? nextScheduleObat,
    String? nextScheduleJumlah,
    int? stokObatPercent,
    bool? statusGelasTerisi,
    List<JadwalItem>? todaySchedule,
  }) {
    return DeviceStatus(
      namaLansia: namaLansia ?? this.namaLansia,
      isDeviceOnline: isDeviceOnline ?? this.isDeviceOnline,
      wifiStatusText: wifiStatusText ?? this.wifiStatusText,
      nextScheduleTime: nextScheduleTime ?? this.nextScheduleTime,
      nextScheduleObat: nextScheduleObat ?? this.nextScheduleObat,
      nextScheduleJumlah: nextScheduleJumlah ?? this.nextScheduleJumlah,
      stokObatPercent: stokObatPercent ?? this.stokObatPercent,
      statusGelasTerisi: statusGelasTerisi ?? this.statusGelasTerisi,
      todaySchedule: todaySchedule ?? this.todaySchedule,
    );
  }
}
