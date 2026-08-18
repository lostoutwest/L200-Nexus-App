import 'package:flutter/foundation.dart';

import '../models/vehicle_state.dart';

enum EnginePhase { off, cranking, running }

abstract class VehicleService extends ChangeNotifier {
  VehicleState get vehicleState;
  bool get isConnected;
  String get connectionLabel;
  EnginePhase get enginePhase;

  Future<void> initialize();

  Future<void> lockDoors();
  Future<void> unlockDoors();
  Future<void> ignitionOn();
  Future<void> ignitionOff();
  Future<void> startEngine();
  Future<void> stopEngine();
  Future<void> headlights(bool state);
  Future<void> calibrateTilt();

  Future<void> refreshStatus();
}
