import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';

typedef MessageCallback = void Function(String topic, String payload);
typedef ConnectionChangedCallback = void Function(bool isConnected);

class MqttService {
  final String broker;
  final int port;
  final String clientId;
  final String username;
  final String password;

  late MqttServerClient client;
  bool _isConnected = false;

  MqttService({
    required this.broker,
    required this.port,
    required this.clientId,
    required this.username,
    required this.password,
  }) {
    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;
    client.setProtocolV311();
    client.keepAlivePeriod = 30;
    client.connectTimeoutPeriod = 8000;
    client.autoReconnect = true;
  }

  bool get isConnected => _isConnected;

  Future<bool> connect(
    MessageCallback onMessage, {
    ConnectionChangedCallback? onConnectionChanged,
  }) async {
    try {
      debugPrint('MQTT: Menghubungkan ke $broker:$port...');

      client.onConnected = () {
        _isConnected = true;
        debugPrint('MQTT: Berhasil terhubung ke broker');
        onConnectionChanged?.call(true);
      };

      client.onDisconnected = () {
        _isConnected = false;
        debugPrint('MQTT: Terputus dari broker');
        onConnectionChanged?.call(false);
      };

      client.onAutoReconnect = () {
        debugPrint('MQTT: Melakukan auto-reconnect...');
      };

      client.onAutoReconnected = () {
        _isConnected = true;
        debugPrint('MQTT: Auto-reconnect berhasil');
        onConnectionChanged?.call(true);
      };

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .startClean();
      client.connectionMessage = connMessage;

      await client.connect();

      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        _isConnected = true;

        client.updates!.listen((List<MqttReceivedMessage<MqttMessage>>? messages) {
          if (messages == null || messages.isEmpty) return;

          for (var message in messages) {
            final recMess = message.payload as MqttPublishMessage;
            final topic = message.topic;
            final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

            debugPrint('MQTT: Pesan diterima dari topic "$topic": $payload');
            onMessage(topic, payload);
          }
        });

        return true;
      } else {
        debugPrint('MQTT: Gagal terhubung, status: ${client.connectionStatus}');
        return false;
      }
    } catch (e) {
      debugPrint('MQTT: Exception saat connect: $e');
      _isConnected = false;
      return false;
    }
  }

  void subscribe(String topic) {
    if (_isConnected) {
      client.subscribe(topic, MqttQos.atLeastOnce);
      debugPrint('MQTT: Subscribe ke topic "$topic"');
    }
  }

  void publish(String topic, String message) {
    if (_isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('MQTT: Publish ke topic "$topic": $message');
    } else {
      debugPrint('MQTT: Tidak dapat publish, koneksi terputus');
    }
  }

  void disconnect() {
    if (_isConnected) {
      client.disconnect();
      _isConnected = false;
      debugPrint('MQTT: Disconnected dari broker');
    }
  }
}