import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/vehicle_state.dart';
import '../protocol/l200_protocol.dart';
import 'vehicle_service.dart';

class WifiVehicleService extends ChangeNotifier implements VehicleService {
  WifiVehicleService({VehicleState initialState = const VehicleState.preview()})
    : _vehicleState = initialState;

  static const String _baseUrl = L200Protocol.wifiBaseUrl;
  static const Duration _timeout = Duration(seconds: 3);

  bool _connected = false;
  bool _disposed = false;
  bool _connecting = false;
  VehicleState _vehicleState;
  EnginePhase _enginePhase = EnginePhase.off;
  Timer? _statusTimer;
  Timer? _retryTimer;

  @override
  bool get isConnected => _connected;

  @override
  VehicleState get vehicleState => _vehicleState;

  @override
  EnginePhase get enginePhase => _enginePhase;

  @override
  String get connectionLabel => _connected ? 'WiFi' : 'WiFi...';

  @override
  Future<void> initialize() async {
    _tryConnect();
  }

  void _tryConnect() {
    if (_disposed || _connecting || _connected) return;
    _connecting = true;
    _checkConnection().then((ok) {
      _connecting = false;
      if (ok) {
        _connected = true;
        _startStatusPolling();
        unawaited(refreshStatus());
        _retryTimer?.cancel();
      } else {
        _scheduleRetry();
      }
      _notify();
    });
  }

  Future<bool> _checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/status'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 3), _tryConnect);
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(refreshStatus());
    });
  }

  @override
  Future<void> refreshStatus() async {
    if (_disposed) return;
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/status'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _vehicleState = VehicleState.fromJson(json, fallback: _vehicleState);
        if (!_connected) {
          _connected = true;
          _startStatusPolling();
          _retryTimer?.cancel();
        }
        _updateEnginePhase();
        _notify();
      } else {
        _handleLostConnection();
      }
    } catch (_) {
      _handleLostConnection();
    }
  }

  void _handleLostConnection() {
    if (_connected) {
      _connected = false;
      _statusTimer?.cancel();
      _scheduleRetry();
      _notify();
    }
  }

  void _updateEnginePhase() {
    if (_vehicleState.engineRunning) {
      _enginePhase = EnginePhase.running;
    } else {
      _enginePhase = EnginePhase.off;
    }
  }

  Future<void> _postCommand(String command) async {
    if (_disposed) return;
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/api/command'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'command': command}),
          )
          .timeout(_timeout);
      _connected = true;
    } catch (_) {
      _handleLostConnection();
    }
  }

  @override
  Future<void> lockDoors() async {
    await _postCommand(L200Protocol.lock);
    _vehicleState = _vehicleState.copyWith(locked: true);
    _notify();
  }

  @override
  Future<void> unlockDoors() async {
    await _postCommand(L200Protocol.unlock);
    _vehicleState = _vehicleState.copyWith(locked: false);
    _notify();
  }

  @override
  Future<void> ignitionOn() async {
    await _postCommand(L200Protocol.ignitionOn);
    _notify();
  }

  @override
  Future<void> ignitionOff() async {
    await _postCommand(L200Protocol.ignitionOff);
    _notify();
  }

  @override
  Future<void> startEngine() async {
    _enginePhase = EnginePhase.cranking;
    _notify();
    await _postCommand(L200Protocol.startEngine);
  }

  @override
  Future<void> stopEngine() async {
    await _postCommand(L200Protocol.stopEngine);
    _enginePhase = EnginePhase.off;
    _notify();
  }

  @override
  Future<void> headlights(bool state) async {
    await _postCommand(
      state ? L200Protocol.headlightsOn : L200Protocol.headlightsOff,
    );
    _vehicleState = _vehicleState.copyWith(headlightsOn: state);
    _notify();
  }

  @override
  Future<void> calibrateTilt() async {
    await _postCommand(L200Protocol.calibrateTilt);
    await refreshStatus();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _statusTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
