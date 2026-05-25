import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

import '../bluetooth/bluetooth_service.dart' as swim_ble;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final swim_ble.BluetoothService bluetoothService =
      swim_ble.BluetoothService();
  bool bluetoothEnabled = false;
  bool scanning = false;
  bool sensorConnected = false;
  bool usbModeEnabled = false;

  BluetoothDevice? connectedDevice;
  List<ScanResult> devices = [];

  Timer? clockTimer;
  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<bool>? connectionSubscription;
  StreamSubscription<BluetoothAdapterState>? adapterSubscription;

  DateTime now = DateTime.now();
  late AnimationController pulseController;

  @override
  void initState() {
    super.initState();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.45,
      upperBound: 1.0,
    )..repeat(reverse: true);

    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => now = DateTime.now());
    });

    listenToBluetoothState();
    listenToService();
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    adapterSubscription?.cancel();
    pulseController.dispose();
    super.dispose();
  }

  void listenToBluetoothState() {
    adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      setState(() {
        bluetoothEnabled = state == BluetoothAdapterState.on;
      });
    });
  }

  void listenToService() {
    scanSubscription = bluetoothService.scanResults.listen((results) {
      if (!mounted) return;
      setState(() => devices = results);
    });

    connectionSubscription = bluetoothService.connectionState.listen((
      connected,
    ) {
      if (!mounted) return;
      setState(() {
        sensorConnected = connected;
        connectedDevice = bluetoothService.connectedDevice;
        if (connected) usbModeEnabled = false;
      });
    });
  }

  Future<void> startScan() async {
    if (!bluetoothEnabled) {
      showMessage('Bluetooth is not enabled.');
      return;
    }

    setState(() {
      scanning = true;
      devices.clear();
    });

    try {
      await bluetoothService.startScan();
      await Future.delayed(const Duration(seconds: 6));
    } catch (e) {
      showMessage('Scan failed: $e');
    } finally {
      await bluetoothService.stopScan();
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    try {
      setState(() => scanning = false);

      showMessage('Connecting to sensor...');

      await bluetoothService.connect(device);

      if (!mounted) return;

      setState(() {
        connectedDevice = bluetoothService.connectedDevice;
        sensorConnected = bluetoothService.isConnected;
        usbModeEnabled = false;
      });

      showMessage('Connected to ${deviceName(device)}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sensorConnected = false;
        connectedDevice = null;
      });

      showMessage('Connection failed: $e');
    }
  }

  Future<void> disconnectDevice() async {
    try {
      await bluetoothService.disconnect();

      if (!mounted) return;

      setState(() {
        connectedDevice = null;
        sensorConnected = false;
      });

      showMessage('Sensor disconnected.');
    } catch (e) {
      showMessage('Could not disconnect: $e');
    }
  }

  void toggleUsbMode() {
    setState(() {
      usbModeEnabled = !usbModeEnabled;

      if (usbModeEnabled) {
        sensorConnected = true;
        connectedDevice = null;
      } else {
        sensorConnected = bluetoothService.isConnected;
        connectedDevice = bluetoothService.connectedDevice;
      }
    });

    showMessage(
      usbModeEnabled
          ? 'USB-C mode enabled. Serial integration will be connected next.'
          : 'USB-C mode disabled.',
    );
  }

  Future<void> runCalibration(String mode) async {
    try {
      if (mode == 'Zero Front Sensor') {
        await bluetoothService.zeroFrontSensor();
      } else if (mode == 'Zero Back Sensor') {
        await bluetoothService.zeroBackSensor();
      } else {
        await bluetoothService.zeroBothSensors();
      }

      showMessage('$mode command sent.');
    } catch (_) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              backgroundColor: const Color(0xFF061226),
              title: Text(mode),
              content: Text(
                '$mode has been queued.\n\n'
                'No live BLE command was sent because no writable sensor characteristic is connected yet.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
      );
    }
  }

  String formatClock() => DateFormat('h:mm:ss a').format(now);

  String formatDate() => DateFormat('MMMM d, yyyy').format(now);

  String deviceName(BluetoothDevice device) {
    return device.platformName.isEmpty ? 'Unknown Sensor' : device.platformName;
  }

  Color connectionColor() {
    if (sensorConnected) return Colors.greenAccent;
    if (usbModeEnabled) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String connectionLabel() {
    if (usbModeEnabled) return 'USB-C Mode Active';
    if (sensorConnected) return 'Sensor Connected';
    return 'Sensor Not Connected';
  }

  String connectionSubtitle() {
    if (usbModeEnabled) {
      return 'USB-C serial mode is selected for wired sensor testing.';
    }

    if (sensorConnected && connectedDevice != null) {
      return 'Connected to ${deviceName(connectedDevice!)}';
    }

    return 'Connect Bluetooth sensor or enable USB-C mode.';
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget settingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget statusDot(Color color) {
    return FadeTransition(
      opacity: pulseController,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.7),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white12,
          disabledForegroundColor: Colors.white38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget sensorStatusCard() {
    return settingsCard(
      child: Column(
        children: [
          Row(
            children: [
              statusDot(connectionColor()),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectionLabel(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      connectionSubtitle(),
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              statusDot(
                bluetoothEnabled ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  bluetoothEnabled ? 'Bluetooth Enabled' : 'Bluetooth Disabled',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttons = [
                actionButton(
                  text: scanning ? 'Scanning...' : 'Scan Devices',
                  icon: Icons.bluetooth_searching_rounded,
                  color: const Color(0xFF1976FF),
                  onPressed: scanning ? null : startScan,
                ),
                actionButton(
                  text:
                      sensorConnected && connectedDevice != null
                          ? 'Disconnect BLE'
                          : 'Disconnect',
                  icon: Icons.bluetooth_disabled_rounded,
                  color: Colors.redAccent,
                  onPressed:
                      sensorConnected && connectedDevice != null
                          ? disconnectDevice
                          : null,
                ),
                actionButton(
                  text: usbModeEnabled ? 'Disable USB-C Mode' : 'USB-C Mode',
                  icon: Icons.usb_rounded,
                  color: const Color(0xFF00B8A9),
                  onPressed: toggleUsbMode,
                ),
              ];

              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    buttons[0],
                    const SizedBox(height: 14),
                    buttons[1],
                    const SizedBox(height: 14),
                    buttons[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: 16),
                  Expanded(child: buttons[1]),
                  const SizedBox(width: 16),
                  Expanded(child: buttons[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget availableDevicesSection() {
    if (devices.isEmpty) {
      return settingsCard(
        child: const Column(
          children: [
            Icon(
              Icons.bluetooth_disabled_rounded,
              size: 60,
              color: Colors.white38,
            ),
            SizedBox(height: 14),
            Text(
              'No devices found',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Press Scan Devices to search for force sensors.',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          devices.map((device) {
            final name = deviceName(device.device);
            final rssi = device.rssi;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF111C2E),
                borderRadius: BorderRadius.circular(22),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1976FF),
                  child: Icon(Icons.memory_rounded),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${device.device.remoteId.str}\nRSSI: $rssi dBm',
                  style: const TextStyle(color: Colors.white60),
                ),
                isThreeLine: true,
                trailing: ElevatedButton(
                  onPressed: () => connectDevice(device.device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B8A9),
                  ),
                  child: const Text('Connect'),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget calibrationSection() {
    return settingsCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttons = [
            actionButton(
              text: 'Zero Front Sensor',
              icon: Icons.tune_rounded,
              color: Colors.orange,
              onPressed: () => runCalibration('Zero Front Sensor'),
            ),
            actionButton(
              text: 'Zero Back Sensor',
              icon: Icons.tune_rounded,
              color: const Color(0xFF6C4DFF),
              onPressed: () => runCalibration('Zero Back Sensor'),
            ),
            actionButton(
              text: 'Full System Calibration',
              icon: Icons.precision_manufacturing_rounded,
              color: Colors.redAccent,
              onPressed: () => runCalibration('Full System Calibration'),
            ),
          ];

          if (constraints.maxWidth < 700) {
            return Column(
              children: [
                buttons[0],
                const SizedBox(height: 14),
                buttons[1],
                const SizedBox(height: 14),
                buttons[2],
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: 16),
                  Expanded(child: buttons[1]),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: buttons[2]),
            ],
          );
        },
      ),
    );
  }

  Widget hardwareRoadmap() {
    return settingsCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoadmapItem(text: 'Bluetooth LE force sensor support'),
          _RoadmapItem(text: 'USB-C serial force sensor mode'),
          _RoadmapItem(text: 'Real-time front/back force streaming'),
          _RoadmapItem(text: 'ESP32 + HX711 force plate integration'),
          _RoadmapItem(text: 'Front/back calibration and tare system'),
          _RoadmapItem(text: 'Sensor latency, battery, and packet monitoring'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    connectedDevice = bluetoothService.connectedDevice;
    sensorConnected = bluetoothService.isConnected || usbModeEnabled;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatClock(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatDate(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              sectionTitle('Sensor Status'),
              sensorStatusCard(),
              const SizedBox(height: 28),
              sectionTitle('Available Devices'),
              availableDevicesSection(),
              const SizedBox(height: 28),
              sectionTitle('Sensor Calibration'),
              calibrationSection(),
              const SizedBox(height: 28),
              sectionTitle('Hardware Roadmap'),
              hardwareRoadmap(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoadmapItem extends StatelessWidget {
  final String text;

  const _RoadmapItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
