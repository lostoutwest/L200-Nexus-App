import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  StreamSubscription<Position>? _positionSubscription;
  bool _disposed = false;

  Position? _lastPosition;
  String? _error;

  Position? get lastPosition => _lastPosition;
  String? get error => _error;
  bool get hasLocation => _lastPosition != null;

  /// [lat, lng] formatted to 6 decimal places, or null if no fix yet.
  String? get coordinateLabel {
    final p = _lastPosition;
    if (p == null) return null;
    return '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
  }

  Future<void> start() async {
    if (_disposed) return;

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _error = 'Location services are disabled.';
      _notify();
      return;
    }

    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    if (status == LocationPermission.deniedForever) {
      _error = 'Location permission permanently denied.';
      _notify();
      return;
    }
    if (status == LocationPermission.denied) {
      _error = 'Location permission denied.';
      _notify();
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) {
        _lastPosition = position;
        _error = null;
        _notify();
      },
      onError: (e) {
        _error = e.toString();
        _notify();
      },
    );
  }

  Future<void> refresh() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _lastPosition = pos;
      _error = null;
      _notify();
    } catch (e) {
      _error = e.toString();
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
