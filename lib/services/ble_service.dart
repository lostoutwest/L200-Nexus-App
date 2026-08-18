import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/vehicle_state.dart';
import '../protocol/l200_protocol.dart';
import 'vehicle_service.dart';

enum BleConnectionPhase {
  starting,
  scanning,
  connecting,
  connected,
  reconnecting,
  disconnected,
}

class BleVehicleService extends ChangeNotifier implements VehicleService {
  BleVehicleService({VehicleState initialState = const VehicleState.preview()})
    : _vehicleState = initialState;

  static const String deviceName = L200Protocol.deviceName;
  static const String serviceUuid = L200Protocol.serviceUuid;
  static const String commandUuid = L200Protocol.commandUuid;
  static const String statusUuid = L200Protocol.statusUuid;

  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _statusCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  Timer? _reconnectTimer;
  bool _connecting = false;
  bool _disposed = false;
  bool _hasConnected = false;
  VehicleState _vehicleState;
  EnginePhase _enginePhase = EnginePhase.off;

  BleConnectionPhase phase = BleConnectionPhase.starting;

  @override
  bool get isConnected => phase == BleConnectionPhase.connected;

  @override
  VehicleState get vehicleState => _vehicleState;

  @override
  EnginePhase get enginePhase => _enginePhase;

  @override
  String get connectionLabel => switch (phase) {
    BleConnectionPhase.starting => 'Starting...',
    BleConnectionPhase.scanning => 'Scanning...',
    BleConnectionPhase.connecting => 'Connecting...',
    BleConnectionPhase.connected => 'BLE',
    BleConnectionPhase.reconnecting => 'Reconnecting...',
    BleConnectionPhase.disconnected => 'Disconnected',
  };

  @override
  Future<void> initialize() async {
    try {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      await _scanAndConnect();
    } catch (_) {
      _setPhase(BleConnectionPhase.disconnected);
      _scheduleReconnect();
    }
  }

  Future<void> _scanAndConnect() async {
    if (_disposed || _connecting || isConnected) return;

    _setPhase(
      _hasConnected
          ? BleConnectionPhase.reconnecting
          : BleConnectionPhase.scanning,
    );

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;
        if (name == deviceName) {
          unawaited(_connect(result.device));
          break;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 17), () {
        if (!isConnected && !_connecting) _scheduleReconnect();
      });
    } catch (_) {
      _scheduleReconnect();
    }
  }

  Future<void> connectTo(BluetoothDevice device) async {
    _reconnectTimer?.cancel();
    await _scanSubscription?.cancel();
    if (!_disposed) {
      await FlutterBluePlus.stopScan();
      await _connect(device);
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (_connecting || isConnected || _disposed) return;
    _connecting = true;
    _reconnectTimer?.cancel();
    await FlutterBluePlus.stopScan();
    _setPhase(BleConnectionPhase.connecting);

    try {
      try {
        await device.connect(license: License.nonprofit, autoConnect: false);
      } catch (_) {}

      final services = await device.discoverServices();
      _commandCharacteristic = _findCharacteristic(services, commandUuid);
      _statusCharacteristic = _findCharacteristic(services, statusUuid);
      if (_commandCharacteristic == null || _statusCharacteristic == null) {
        throw StateError('L200 command or status characteristic was not found');
      }

      await _setupNotifications();

      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && _hasConnected) {
          _handleDisconnect();
        }
        if (state == BluetoothConnectionState.connected && _hasConnected) {
          unawaited(_redicoverServices(device));
        }
      });

      _hasConnected = true;
      _setPhase(BleConnectionPhase.connected);
      unawaited(refreshStatus());
    } catch (_) {
      _handleDisconnect();
    } finally {
      _connecting = false;
    }
  }

  Future<void> _redicoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      _commandCharacteristic = _findCharacteristic(services, commandUuid);
      _statusCharacteristic = _findCharacteristic(services, statusUuid);
      if (_commandCharacteristic != null && _statusCharacteristic != null) {
        await _setupNotifications();
        _setPhase(BleConnectionPhase.connected);
        unawaited(refreshStatus());
      }
    } catch (_) {
      _handleDisconnect();
    }
  }

  BluetoothCharacteristic? _findCharacteristic(
    List<BluetoothService> services,
    String uuid,
  ) {
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() != serviceUuid.toLowerCase()) {
        continue;
      }
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() ==
            uuid.toLowerCase()) {
          return characteristic;
        }
      }
    }
    return null;
  }

  Future<void> _setupNotifications() async {
    final characteristic = _statusCharacteristic;
    if (characteristic == null) return;

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    if (characteristic.properties.notify) {
      await characteristic.setNotifyValue(true);
      _notificationSubscription = characteristic.onValueReceived.listen(
        _onNotificationReceived,
        onError: (_) {},
      );
    }
  }

  void _onNotificationReceived(List<int> data) {
    try {
      final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      _vehicleState = VehicleState.fromJson(json, fallback: _vehicleState);
      _updateEnginePhase();
      _notify();
    } catch (_) {}
  }

  void _handleDisconnect() {
    _commandCharacteristic = null;
    _statusCharacteristic = null;
    unawaited(_notificationSubscription?.cancel());
    _notificationSubscription = null;
    if (!_disposed) {
      _setPhase(BleConnectionPhase.reconnecting);
      _scheduleReconnect();
    }
  }

  void stopScanAndRetry() {
    _reconnectTimer?.cancel();
    unawaited(_scanSubscription?.cancel());
    _scanAndConnect();
  }

  void _scheduleReconnect() {
    if (_disposed || isConnected) return;
    _setPhase(BleConnectionPhase.reconnecting);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _scanAndConnect);
  }

  Future<void> _sendCommand(String command) async {
    final characteristic = _commandCharacteristic;
    if (!isConnected || characteristic == null) return;
    await characteristic.write(utf8.encode(command), withoutResponse: false);
  }

  @override
  Future<void> refreshStatus() async {
    await _sendCommand(L200Protocol.status);
  }

  void _updateEnginePhase() {
    if (_vehicleState.engineRunning) {
      _enginePhase = EnginePhase.running;
    } else {
      _enginePhase = EnginePhase.off;
    }
  }

  @override
  Future<void> lockDoors() async {
    if (!isConnected) return;
    try {
      await _sendCommand(L200Protocol.lock);
      _vehicleState = _vehicleState.copyWith(locked: true);
      _notify();
    } catch (_) {}
  }

  @override
  Future<void> unlockDoors() async {
    if (!isConnected) return;
    try {
      await _sendCommand(L200Protocol.unlock);
      _vehicleState = _vehicleState.copyWith(locked: false);
      _notify();
    } catch (_) {}
  }

  @override
  Future<void> ignitionOn() async {
    if (!isConnected) return;
    try {
      await _sendCommand(L200Protocol.ignitionOn);
      _notify();
    } catch (_) {}
  }

  @override
  Future<void> ignitionOff() async {
    if (!isConnected) return;
    try {
      await _sendCommand(L200Protocol.ignitionOff);
      _notify();
    } catch (_) {}
  }

  @override
  Future<void> startEngine() async {
    if (!isConnected) return;
    _enginePhase = EnginePhase.cranking;
    _notify();
    try {
      await _sendCommand(L200Protocol.startEngine);
    } catch (_) {
      _enginePhase = EnginePhase.off;
      _notify();
    }
  }

  @override
  Future<void> stopEngine() async {
    if (!isConnected) return;
    try {
      await _sendCommand(L200Protocol.stopEngine);
      _enginePhase = EnginePhase.off;
      _notify();
    } catch (_) {}
  }

  @override
  Future<void> headlights(bool state) async {
    if (!isConnected) return;
    try {
      await _sendCommand(
        state ? L200Protocol.headlightsOn : L200Protocol.headlightsOff,
      );
      _vehicleState = _vehicleState.copyWith(headlightsOn: state);
      _notify();
    } catch (_) {}
  }

  @override
  Future<void> calibrateTilt() async {
    if (!isConnected) return;
    await _sendCommand(L200Protocol.calibrateTilt);
    await refreshStatus();
  }

  void _setPhase(BleConnectionPhase value) {
    phase = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    unawaited(_scanSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    unawaited(_notificationSubscription?.cancel());
    super.dispose();
  }
}
