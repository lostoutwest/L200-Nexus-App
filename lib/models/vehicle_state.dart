class VehicleState {
  const VehicleState({
    required this.locked,
    required this.batteryVoltage,
    required this.temperatureCelsius,
    required this.waterTemperature,
    required this.engineRunning,
    required this.ignition,
    required this.headlightsOn,
    required this.signalRssi,
    required this.tiltPitch,
    required this.tiltRoll,
    required this.tiltValid,
    required this.tiltStatus,
  });

  const VehicleState.preview()
    : locked = true,
      batteryVoltage = 12.6,
      temperatureCelsius = 82,
      waterTemperature = 88,
      engineRunning = false,
      ignition = false,
      headlightsOn = false,
      signalRssi = 0,
      tiltPitch = 0,
      tiltRoll = 0,
      tiltValid = false,
      tiltStatus = 'unavailable';

  final bool locked;
  final double batteryVoltage;
  final double temperatureCelsius;
  final double waterTemperature;
  final bool engineRunning;
  final bool ignition;
  final bool headlightsOn;
  final int signalRssi;
  final double tiltPitch;
  final double tiltRoll;
  final bool tiltValid;
  final String tiltStatus;

  bool get ignitionOn => ignition;

  factory VehicleState.fromJson(
    Map<String, dynamic> json, {
    VehicleState fallback = const VehicleState.preview(),
  }) {
    return VehicleState(
      locked: json['locked'] as bool? ?? fallback.locked,
      batteryVoltage:
          (json['battery'] as num?)?.toDouble() ??
          (json['voltage'] as num?)?.toDouble() ??
          fallback.batteryVoltage,
      waterTemperature:
          (json['water_temp'] as num?)?.toDouble() ??
          (json['water_temperature'] as num?)?.toDouble() ??
          fallback.waterTemperature,
      temperatureCelsius:
          (json['temp'] as num?)?.toDouble() ??
          (json['engine_temp'] as num?)?.toDouble() ??
          (json['engine_temperature'] as num?)?.toDouble() ??
          (json['water_temperature'] as num?)?.toDouble() ??
          fallback.temperatureCelsius,
      engineRunning:
          json['engine'] as bool? ??
          fallback.engineRunning,
      ignition: json['ignition'] as bool? ?? fallback.ignition,
      headlightsOn: json['headlights'] as bool? ?? fallback.headlightsOn,
      signalRssi: json['signal'] as int? ?? fallback.signalRssi,
      tiltPitch: (json['tiltPitch'] as num?)?.toDouble() ?? fallback.tiltPitch,
      tiltRoll: (json['tiltRoll'] as num?)?.toDouble() ?? fallback.tiltRoll,
      tiltValid: json['tiltValid'] as bool? ?? fallback.tiltValid,
      tiltStatus: (json['tiltStatus'] as String?) ?? fallback.tiltStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'locked': locked,
    'battery': batteryVoltage,
    'temp': temperatureCelsius,
    'water_temp': waterTemperature,
    'engine': engineRunning,
    'ignition': ignition,
    'headlights': headlightsOn,
    'signal': signalRssi,
    'tiltPitch': tiltPitch,
    'tiltRoll': tiltRoll,
    'tiltValid': tiltValid,
    'tiltStatus': tiltStatus,
  };

  VehicleState copyWith({
    bool? locked,
    double? batteryVoltage,
    double? temperatureCelsius,
    double? waterTemperature,
    bool? engineRunning,
    bool? ignition,
    bool? headlightsOn,
    int? signalRssi,
    double? tiltPitch,
    double? tiltRoll,
    bool? tiltValid,
    String? tiltStatus,
  }) {
    return VehicleState(
      locked: locked ?? this.locked,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      waterTemperature: waterTemperature ?? this.waterTemperature,
      engineRunning: engineRunning ?? this.engineRunning,
      ignition: ignition ?? this.ignition,
      headlightsOn: headlightsOn ?? this.headlightsOn,
      signalRssi: signalRssi ?? this.signalRssi,
      tiltPitch: tiltPitch ?? this.tiltPitch,
      tiltRoll: tiltRoll ?? this.tiltRoll,
      tiltValid: tiltValid ?? this.tiltValid,
      tiltStatus: tiltStatus ?? this.tiltStatus,
    );
  }
}
