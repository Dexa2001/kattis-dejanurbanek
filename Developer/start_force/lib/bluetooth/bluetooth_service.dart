import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ForceSensorReading {
  final double frontKgf;
  final double backKgf;
  final double totalKgf;
  final int timestampMs;
  final DateTime receivedAt;

  const ForceSensorReading({
    required this.frontKgf,
    required this.backKgf,
    required this.totalKgf,
    required this.timestampMs,
    required this.receivedAt,
  });

  factory ForceSensorReading.fromPacket(String packet) {
    final cleaned = packet.trim();

    double front = 0;
    double back = 0;
    int time = 0;

    // Supported packet:
    // FRONT:74.2,BACK:91.6,TIME:120
    final parts = cleaned.split(',');

    for (final part in parts) {
      final split = part.split(':');
      if (split.length != 2) continue;

      final key = split[0].trim().toUpperCase();
      final value = split[1].trim();

      if (key == 'FRONT') {
        front = double.tryParse(value) ?? 0;
      } else if (key == 'BACK') {
        back = double.tryParse(value) ?? 0;
      } else if (key == 'TIME') {
        time = int.tryParse(value) ?? 0;
      }
    }

    return ForceSensorReading(
      frontKgf: front,
      backKgf: back,
      totalKgf: front + back,
      timestampMs: time,
      receivedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frontKgf': frontKgf,
      'backKgf': backKgf,
      'totalKgf': totalKgf,
      'timestampMs': timestampMs,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }
}

class BluetoothService {
  static final BluetoothService instance = BluetoothService._internal();

  factory BluetoothService() => instance;

  BluetoothService._internal();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? dataCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;

  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();

  final StreamController<ForceSensorReading> _readingController =
      StreamController<ForceSensorReading>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;
  Stream<ForceSensorReading> get readings => _readingController.stream;
  Stream<bool> get connectionState => _connectionController.stream;

  bool get isConnected => connectedDevice != null;

  Future<bool> isBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  Future<void> startScan() async {
    final bluetoothOn = await isBluetoothOn();

    if (!bluetoothOn) {
      throw Exception('Bluetooth is not enabled.');
    }

    await stopScan();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final filtered =
          results.where((result) {
            final name = result.device.platformName.toLowerCase();
            final id = result.device.remoteId.str.toLowerCase();

            return name.contains('swim') ||
                name.contains('force') ||
                name.contains('sensor') ||
                name.contains('esp') ||
                name.contains('hx711') ||
                id.isNotEmpty;
          }).toList();

      _scanResultsController.add(filtered);
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 6),
        androidUsesFineLocation: false,
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      final error = e.toString().toLowerCase();

      if (error.contains('requestdevice') ||
          error.contains('user cancelled') ||
          error.contains('notfounderror')) {
        debugPrint('Bluetooth chooser closed.');
        return;
      }

      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<void> connect(BluetoothDevice device) async {
    await stopScan();
    await disconnect();

    await device.connect(
      license: License.free,
      timeout: const Duration(seconds: 10),
    );

    connectedDevice = device;
    _connectionController.add(true);

    _connectionSubscription = device.connectionState.listen((state) {
      final connected = state == BluetoothConnectionState.connected;

      if (!connected) {
        connectedDevice = null;
        dataCharacteristic = null;
      }

      _connectionController.add(connected);
    });

    await _discoverDataCharacteristic(device);
  }

  Future<void> _discoverDataCharacteristic(BluetoothDevice device) async {
    final services = await device.discoverServices(
      subscribeToServicesChanged: false,
    );

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final canNotify = characteristic.properties.notify;
        final canRead = characteristic.properties.read;
        final canWrite =
            characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse;

        if (canNotify || canRead || canWrite) {
          dataCharacteristic = characteristic;

          if (canNotify) {
            await characteristic.setNotifyValue(true);

            _dataSubscription = characteristic.lastValueStream.listen((value) {
              _handleRawData(value);
            });
          }

          return;
        }
      }
    }

    throw Exception('No readable/notifiable sensor characteristic found.');
  }

  void _handleRawData(List<int> value) {
    if (value.isEmpty) return;

    try {
      final packet = utf8.decode(value).trim();

      if (packet.isEmpty) return;

      final reading = ForceSensorReading.fromPacket(packet);

      _readingController.add(reading);
    } catch (_) {
      debugPrint('Ignored malformed BLE packet.');
    }
  }

  Future<void> sendCommand(String command) async {
    if (dataCharacteristic == null) {
      throw Exception('No sensor characteristic connected.');
    }

    final bytes = utf8.encode(command);

    await dataCharacteristic!.write(
      bytes,
      withoutResponse: dataCharacteristic!.properties.writeWithoutResponse,
    );
  }

  Future<void> zeroFrontSensor() async {
    await sendCommand('ZERO_FRONT\n');
  }

  Future<void> zeroBackSensor() async {
    await sendCommand('ZERO_BACK\n');
  }

  Future<void> zeroBothSensors() async {
    await sendCommand('ZERO_BOTH\n');
  }

  Future<void> startStreaming() async {
    await sendCommand('START_STREAM\n');
  }

  Future<void> stopStreaming() async {
    await sendCommand('STOP_STREAM\n');
  }

  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    await _connectionSubscription?.cancel();

    _dataSubscription = null;
    _connectionSubscription = null;
    dataCharacteristic = null;

    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (_) {}
    }

    connectedDevice = null;
    _connectionController.add(false);
  }

  Future<void> dispose() async {
    await stopScan();
    await disconnect();

    await _scanResultsController.close();
    await _readingController.close();
    await _connectionController.close();
  }
}
