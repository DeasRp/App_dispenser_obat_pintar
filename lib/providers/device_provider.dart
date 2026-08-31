import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/constants/mqtt_config.dart';
import '../core/services/auth_service.dart';
import '../core/services/mqtt_service.dart';
import '../core/services/supabase_service.dart';
import '../models/device_status.dart';

class DeviceProvider with ChangeNotifier {
  MqttService? _mqttService;
  MqttService? get mqttService => _mqttService;

  AppProfile? _profile;
  AppProfile? get profile => _profile;
  UserRole? get role => _profile?.role;
  bool get isLansia => role == UserRole.lansia;
  bool get isKeluarga => role == UserRole.keluarga;

  String? _lansiaId;
  String get lansiaId => _lansiaId ?? '';
  bool get sudahTerhubungDenganLansia =>
      _lansiaId != null && _lansiaId!.isNotEmpty;

  DeviceStatus status = DeviceStatus.initial();
  bool isLoading = false;
  bool isMqttConnected = false;
  String? errorMessage;

  Future<void> _muatProfile() async {
    _profile = await AuthService().getCurrentProfile();
    if (_profile == null) {
      throw Exception('Profil pengguna tidak ditemukan.');
    }
  }

  Future<void> _muatLansiaId() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Tidak ada pengguna yang sedang login.');
    }

    if (_profile == null) {
      throw Exception('Profil pengguna belum dimuat.');
    }

    if (_profile!.role == UserRole.lansia) {
      await _muatLansiaUntukAkunLansia(userId);
    } else {
      await _muatLansiaUntukAkunKeluarga(userId);
    }
  }

  Future<void> _muatLansiaUntukAkunLansia(String userId) async {
    final response = await SupabaseService.client
        .from('lansia')
        .select('id, nama')
        .eq('user_id', userId)
        .maybeSingle();

    _lansiaId = response?['id'] as String?;
    final nama = response?['nama'] as String?;

    if (nama != null && nama.isNotEmpty) {
      status = status.copyWith(namaLansia: nama);
    }
  }

  Future<void> _muatLansiaUntukAkunKeluarga(String userId) async {
    final response = await SupabaseService.client
        .from('keluarga_lansia')
        .select('lansia_id, lansia(id, nama)')
        .eq('keluarga_user_id', userId)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      _lansiaId = null;
      return;
    }

    _lansiaId = response['lansia_id'] as String?;

    final lansiaData = response['lansia'];
    if (lansiaData is Map<String, dynamic>) {
      final nama = lansiaData['nama'] as String?;
      if (nama != null && nama.isNotEmpty) {
        status = status.copyWith(namaLansia: nama);
      }
    }
  }

  Future<void> init() async {
    status = DeviceStatus.initial();
    isMqttConnected = false;
    errorMessage = null;
    _profile = null;
    _lansiaId = null;

    _mqttService?.disconnect();
    _mqttService = null;

    isLoading = true;
    notifyListeners();

    try {
      await _muatProfile();
      await _muatLansiaId();

      if (!sudahTerhubungDenganLansia) {
        return;
      }

      final mqtt = MqttService(
        broker: MqttConfig.broker,
        port: MqttConfig.port,
        clientId:
            'flutter_dispenser_obat_${DateTime.now().millisecondsSinceEpoch}',
        username: MqttConfig.username,
        password: MqttConfig.password,
      );

      _mqttService = mqtt;

      final connected = await mqtt.connect(
        _handleMessage,
        onConnectionChanged: (isConnected) {
          isMqttConnected = isConnected;
          notifyListeners();
        },
      );

      if (connected) {
        isMqttConnected = true;

        mqtt.subscribe(MqttConfig.topicMedicineStatus);
        mqtt.subscribe(MqttConfig.topicMedicineStock);
        mqtt.subscribe(MqttConfig.topicMedicineGlass);
        mqtt.subscribe(MqttConfig.topicMedicineSchedule);
        mqtt.subscribe(MqttConfig.topicMedicineHistory);
        mqtt.subscribe(MqttConfig.topicMedicineNotify);

        mqtt.publish(MqttConfig.topicCmdSetLansia, _lansiaId!);

        await Future.delayed(const Duration(milliseconds: 500));
        await refreshDeviceStatus();
      }
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('DeviceProvider init gagal: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLansiaConnection() async {
    await init();
  }

  void _handleMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      switch (topic) {
        case MqttConfig.topicMedicineStatus:
          status = status.copyWith(
            isDeviceOnline: data['online'] ?? false,
            wifiStatusText: data['wifi'] ?? 'Tidak terhubung',
          );
          break;

        case MqttConfig.topicMedicineStock:
          status = status.copyWith(
            stokObatPercent: data['percent'] ?? 0,
          );
          break;

        case MqttConfig.topicMedicineGlass:
          status = status.copyWith(
            statusGelasTerisi: data['filled'] ?? false,
          );
          break;

        case MqttConfig.topicMedicineSchedule:
          final nextData = data['next'] as Map<String, dynamic>?;
          if (nextData != null) {
            status = status.copyWith(
              nextScheduleTime: nextData['time'] ?? '--:--',
              nextScheduleObat: nextData['obat'] ?? '-',
              nextScheduleJumlah: nextData['jumlah'] ?? '-',
            );
          }

          final todayData = data['today'] as List<dynamic>?;
          if (todayData != null) {
            final schedules = todayData
                .map((item) => JadwalItem.fromJson(item as Map<String, dynamic>))
                .toList();
            status = status.copyWith(todaySchedule: schedules);
          }
          break;

        default:
          break;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing MQTT payload dari topic $topic: $e');
    }
  }

  Future<void> refreshDeviceStatus() async {
    _mqttService?.publish(MqttConfig.topicCmdRefresh, '1');
  }

  void publishDispenseCommand() {
    _mqttService?.publish(MqttConfig.topicCmdDispense, '1');
  }

  @override
  void dispose() {
    _mqttService?.disconnect();
    super.dispose();
  }
}
