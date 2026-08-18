import 'package:flutter_test/flutter_test.dart';
import 'package:l200_app/models/vehicle_state.dart';

void main() {
  test('STATUS payload (V1 BLE format) updates every supported field', () {
    final state = VehicleState.fromJson({
      'locked': false,
      'voltage': 12.4,
      'water_temperature': 87,
      'engine_temperature': 94,
      'oil_pressure': 48,
      'engine': true,
      'ignition': true,
      'headlights': true,
    });

    expect(state.locked, isFalse);
    expect(state.batteryVoltage, 12.4);
    expect(state.temperatureCelsius, 94);
    expect(state.engineRunning, isTrue);
    expect(state.headlightsOn, isTrue);
  });

  test('STATUS payload (V2 HTTP format) updates every supported field', () {
    final state = VehicleState.fromJson({
      'locked': false,
      'battery': 12.7,
      'temp': 84,
      'engine': true,
      'headlights': true,
      'signal': -52,
    });

    expect(state.locked, isFalse);
    expect(state.batteryVoltage, 12.7);
    expect(state.temperatureCelsius, 84);
    expect(state.engineRunning, isTrue);
    expect(state.headlightsOn, isTrue);
    expect(state.signalRssi, -52);
  });

  test('V1 fields fall through when V2 field names are present', () {
    final state = VehicleState.fromJson({
      'battery': 12.7,
      'temp': 84,
      'engine': true,
    });

    expect(state.batteryVoltage, 12.7);
    expect(state.temperatureCelsius, 84);
    expect(state.engineRunning, isTrue);
    expect(state.signalRssi, 0);
  });

  test('preview values used when STATUS is empty', () {
    final state = VehicleState.fromJson({});

    expect(state.locked, true);
    expect(state.batteryVoltage, 12.6);
    expect(state.temperatureCelsius, 82);
    expect(state.engineRunning, false);
    expect(state.headlightsOn, false);
    expect(state.signalRssi, 0);
    expect(state.tiltValid, false);
    expect(state.tiltStatus, 'unavailable');
  });

  test('tilt fields and firmware status are parsed', () {
    final state = VehicleState.fromJson({
      'tiltPitch': -4.25,
      'tiltRoll': 8.5,
      'tiltValid': true,
      'tiltStatus': 'safe',
    });

    expect(state.tiltPitch, -4.25);
    expect(state.tiltRoll, 8.5);
    expect(state.tiltValid, isTrue);
    expect(state.tiltStatus, 'safe');
  });
}
