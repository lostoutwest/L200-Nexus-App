import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/vehicle_state.dart';
import 'vehicle_service.dart';
import 'ble_service.dart';
import 'wifi_service.dart';

enum ConnectionType { ble, wifi, none }

class VehicleServiceProvider extends ChangeNotifier implements VehicleService {
  VehicleServiceProvider({
    VehicleState initialState = const VehicleState.preview(),
  }) : _vehicleState = initialState;

  static const Duration _bleTimeout = Duration(seconds: 12);

  BleVehicleService? _bleService;
  WifiVehicleService? _wifiService;
  VehicleService? _activeService;
  VehicleState _vehicleState;
  EnginePhase _enginePhase = EnginePhase.off;
  ConnectionType _connectionType = ConnectionType.none;
  bool _disposed = false;
  Timer? _bleFallbackTimer;

  @override
  VehicleState get vehicleState => _vehicleState;
  @override
  bool get isConnected => _activeService?.isConnected ?? false;
  @override
  EnginePhase get enginePhase => _enginePhase;
  ConnectionType get connectionType => _connectionType;

  @override
  String get connectionLabel {
    if (_activeService != null && _activeService!.isConnected) {
      return _activeService!.connectionLabel;
    }
    if (_bleService != null && !_disposed) {
      return _bleService!.connectionLabel;
    }
    if (_wifiService != null && !_disposed) {
      return _wifiService!.connectionLabel;
    }
    return 'Disconnected';
  }

  @override
  Future<void> initialize() async {
    _startBle();
    _startBleFallbackTimer();
  }

  void _startBle() {
    _bleService = BleVehicleService(initialState: _vehicleState);
    _bleService!.addListener(_onBleUpdate);
    _bleService!.initialize();
  }

  void _startBleFallbackTimer() {
    _bleFallbackTimer = Timer(_bleTimeout, () {
      if (_disposed) return;
      if (_bleService == null || !_bleService!.isConnected) {
        _startWifi();
      }
    });
  }

  void _onBleUpdate() {
    final ble = _bleService;
    if (ble == null) return;

    if (ble.isConnected) {
      _bleFallbackTimer?.cancel();
      if (_activeService != ble) {
        _setActive(ble, ConnectionType.ble);
      }
    } else if (_activeService == _bleService) {
      _activeService = null;
      _connectionType = ConnectionType.none;
      _tryFallback();
    }

    if (_activeService == ble) {
      _onServiceUpdate();
    } else {
      _notify();
    }
  }

  void _startWifi() {
    if (_disposed || _wifiService != null) return;
    _wifiService = WifiVehicleService(initialState: _vehicleState);
    _wifiService!.addListener(_onWifiUpdate);
    _wifiService!.initialize();
  }

  void _onWifiUpdate() {
    final wifi = _wifiService;
    if (wifi == null) return;

    if (wifi.isConnected) {
      if (_activeService != wifi) {
        _setActive(wifi, ConnectionType.wifi);
      }
    } else if (_activeService == _wifiService) {
      _activeService = null;
      _connectionType = ConnectionType.none;
    }

    if (_activeService == wifi) {
      _onServiceUpdate();
    } else {
      _notify();
    }
  }

  void _tryFallback() {
    if (_wifiService != null) {
      _wifiService!.initialize();
    } else {
      _startWifi();
    }
  }

  void _setActive(VehicleService service, ConnectionType type) {
    if (_activeService == service) return;
    _activeService = service;
    _connectionType = type;
    _onServiceUpdate();
  }

  void _onServiceUpdate() {
    final active = _activeService;
    if (active == null) return;
    _vehicleState = active.vehicleState;
    _enginePhase = active.enginePhase;
    _notify();
  }

  @override
  Future<void> refreshStatus() => _activeService?.refreshStatus() ?? Future.value();

  @override
  Future<void> lockDoors() => _activeService?.lockDoors() ?? Future.value();
  @override
  Future<void> unlockDoors() => _activeService?.unlockDoors() ?? Future.value();
  @override
  Future<void> ignitionOn() => _activeService?.ignitionOn() ?? Future.value();
  @override
  Future<void> ignitionOff() => _activeService?.ignitionOff() ?? Future.value();
  @override
  Future<void> startEngine() => _activeService?.startEngine() ?? Future.value();
  @override
  Future<void> stopEngine() => _activeService?.stopEngine() ?? Future.value();
  @override
  Future<void> headlights(bool state) => _activeService?.headlights(state) ?? Future.value();
  @override
  Future<void> calibrateTilt() => _activeService?.calibrateTilt() ?? Future.value();

  BleVehicleService? get bleService => _bleService;
  WifiVehicleService? get wifiService => _wifiService;

  void forceBleScan() {
    _bleService?.stopScanAndRetry();
  }

  @override
  void dispose() {
    _disposed = true;
    _bleFallbackTimer?.cancel();
    _bleService?.removeListener(_onBleUpdate);
    _wifiService?.removeListener(_onWifiUpdate);
    _bleService?.dispose();
    _wifiService?.dispose();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
