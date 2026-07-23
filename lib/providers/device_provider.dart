
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

// Provider tiruan (mock) untuk mensimulasikan data dari device/MQTT
// Ganti dengan implementasi MQTT asli Anda.
class DeviceProvider with ChangeNotifier {
  // State
  bool _isLoading = true;
  bool _isDeviceOnline = false;
  String _wifiStatusText = "Tidak terhubung";
  String _namaLansia = "Nenek";
  NextSchedule? _nextSchedule;
  int _stokObatPercent = 0;
  GlassStatus _statusGelas = GlassStatus.kosong;
  List<TodaySchedule> _todaySchedule = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isDeviceOnline => _isDeviceOnline;
  String get wifiStatusText => _wifiStatusText;
  String get namaLansia => _namaLansia;
  NextSchedule? get nextSchedule => _nextSchedule;
  int get stokObatPercent => _stokObatPercent;
  GlassStatus get statusGelas => _statusGelas;
  List<TodaySchedule> get todaySchedule => _todaySchedule;

  DeviceProvider() {
    // Saat provider pertama kali dibuat, langsung coba ambil data
    refreshDeviceStatus();
  }

  // Aksi untuk refresh data, dipanggil oleh Pull-to-Refresh
  Future<void> refreshDeviceStatus() async {
    _isLoading = true;
    notifyListeners();

    // Simulasi delay jaringan
    await Future.delayed(const Duration(seconds: 2));

    // Simulasi data sukses diterima
    _isDeviceOnline = true;
    _wifiStatusText = "Terhubung ke 'WiFi Rumah'";
    _namaLansia = "Siti";
    _nextSchedule = NextSchedule(
        jam: "14:00", namaObat: "Paracetamol", jumlah: "1 tablet");
    _stokObatPercent = 65;
    _statusGelas = GlassStatus.terisi;
    _todaySchedule = [
      TodaySchedule(
          jam: "08:00",
          namaObat: "Amlodipine",
          status: ScheduleStatus.sudahDiambil),
      TodaySchedule(
          jam: "14:00",
          namaObat: "Paracetamol",
          status: ScheduleStatus.menunggu),
      TodaySchedule(
          jam: "20:00", namaObat: "Metformin", status: ScheduleStatus.terjadwal),
    ];
    _isLoading = false;

    // Beri tahu semua listener (widget) bahwa data telah berubah
    notifyListeners();
  }

  // Aksi untuk mengirim perintah dispense manual
  Future<void> publishDispenseCommand() async {
    // Di sini logika untuk publish MQTT ke topic 'medicine/cmd/dispense'
    // Contoh: await mqttClient.publish('medicine/cmd/dispense', '1');
    debugPrint("MQTT: Menerbitkan perintah ke topic 'medicine/cmd/dispense'");
    
    // Simulasi feedback, mungkin setelah mendapat balasan dari device
    await Future.delayed(const Duration(seconds: 1));
    debugPrint("MQTT: Perintah dispense berhasil dikirim.");
    // Anda mungkin ingin menampilkan snackbar atau notifikasi di sini
  }
}
