/// Versioned transport contract shared by the Flutter app and L200 firmware.
class L200Protocol {
  static const deviceName = 'L200-NEXUS';
  static const wifiBaseUrl = 'http://192.168.4.1';

  static const serviceUuid = 'D7F0A100-3E91-4C25-9D8A-001122334455';
  static const commandUuid = 'D7F0A101-3E91-4C25-9D8A-001122334455';
  static const statusUuid = 'D7F0A102-3E91-4C25-9D8A-001122334455';

  static const lock = 'LOCK';
  static const unlock = 'UNLOCK';
  static const ignitionOn = 'IGNITION_ON';
  static const ignitionOff = 'IGNITION_OFF';
  static const startEngine = 'START_ENGINE';
  static const stopEngine = 'STOP_ENGINE';
  static const headlightsOn = 'HEADLIGHT_ON';
  static const headlightsOff = 'HEADLIGHT_OFF';
  static const status = 'STATUS';
  static const calibrateTilt = 'CALIBRATE_TILT';
}
