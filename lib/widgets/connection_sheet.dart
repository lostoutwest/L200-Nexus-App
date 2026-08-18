import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show FlutterBluePlus, ScanResult, BluetoothDevice;
import 'package:permission_handler/permission_handler.dart';

import '../services/service_provider.dart';
import '../theme/app_theme.dart';

class ConnectionSheet extends StatefulWidget {
  const ConnectionSheet({required this.provider, super.key});

  final VehicleServiceProvider provider;

  @override
  State<ConnectionSheet> createState() => _ConnectionSheetState();
}

class _ConnectionSheetState extends State<ConnectionSheet> {
  late final VehicleServiceProvider _provider;
  List<ScanResult> _bleDevices = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider;
    _provider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _scanSubscription?.cancel();
    _bleDevices = [];
    super.dispose();
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _scanBle() async {
    setState(() {
      _isScanning = true;
      _bleDevices = [];
    });

    try {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    } catch (_) {}

    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      for (final r in results) {
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;
        if (name.isNotEmpty && !_bleDevices.any((d) => d.device.remoteId == r.device.remoteId)) {
          setState(() => _bleDevices.add(r));
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (_) {}
    await FlutterBluePlus.stopScan();
    if (mounted) setState(() => _isScanning = false);
  }

  void _connectBle(BluetoothDevice device) {
    final ble = _provider.bleService;
    if (ble != null) ble.connectTo(device);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ble = _provider.bleService;
    final wifi = _provider.wifiService;
    final connected = _provider.isConnected;
    final type = _provider.connectionType;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1812), Color(0xFF0D0C08)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'CONNECTION',
                style: TextStyle(
                  color: AppColors.paleGold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              _statusTile(
                icon: connected ? Icons.link : Icons.link_off,
                iconColor: connected ? Colors.greenAccent : Colors.redAccent,
                title: connected ? 'Connected via $type' : 'Disconnected',
                subtitle: _provider.connectionLabel,
              ),
              const SizedBox(height: 20),

              // BLE section
              Row(
                children: [
                  const Icon(Icons.bluetooth, size: 18, color: AppColors.gold),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'BLUETOOTH',
                      style: TextStyle(
                        color: AppColors.paleGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (ble != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ble.isConnected
                            ? Colors.greenAccent.withValues(alpha: 0.15)
                            : Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ble.isConnected
                              ? Colors.greenAccent.withValues(alpha: 0.4)
                              : Colors.redAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        ble.connectionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ble.isConnected ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanning ? null : _scanBle,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                            )
                          : const Icon(Icons.search, size: 16),
                      label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                      style: _outlinedButtonStyle(),
                    ),
                  ),
                  if (ble != null && !ble.isConnected) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _provider.forceBleScan();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                        style: _outlinedButtonStyle(),
                      ),
                    ),
                  ],
                ],
              ),
              if (_bleDevices.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...List.generate(_bleDevices.length, (i) {
                  final d = _bleDevices[i];
                  final name = d.device.platformName.isNotEmpty
                      ? d.device.platformName
                      : d.advertisementData.advName;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.bluetooth_connected, color: AppColors.gold, size: 20),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFFF2E9CD),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${d.rssi} dBm',
                        style: const TextStyle(color: Color(0xFF9E967D), fontSize: 11),
                      ),
                      trailing: TextButton(
                        onPressed: () => _connectBle(d.device),
                        child: const Text('CONNECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              // WiFi section
              Row(
                children: [
                  const Icon(Icons.wifi, size: 18, color: AppColors.gold),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'WiFi',
                      style: TextStyle(
                        color: AppColors.paleGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (wifi != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: wifi.isConnected
                            ? Colors.greenAccent.withValues(alpha: 0.15)
                            : Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: wifi.isConnected
                              ? Colors.greenAccent.withValues(alpha: 0.4)
                              : Colors.redAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        wifi.connectionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: wifi.isConnected ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF9E967D)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Connect your phone to the "L200-NEXUS" WiFi network.\nPassword: L200Nexus',
                        style: const TextStyle(color: Color(0xFF9E967D), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF2E9CD),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF9E967D), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ButtonStyle _outlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.gold,
      side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}
