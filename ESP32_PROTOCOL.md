# L200 ESP32 V2 Protocol

The ESP32-C6 runs both BLE and WiFi AP simultaneously.

WiFi AP: `L200-NEXUS` (password: `L200Nexus`)
BLE name: `L200-NEXUS`

## Canonical firmware pinout

The standalone firmware uses active-low relay outputs on GPIO18 (lock), GPIO19 (unlock), GPIO20 (ignition), GPIO21 (starter), and GPIO22 (headlights). RGB data is GPIO23. Vehicle inputs are GPIO0 (battery ADC), GPIO1 (engine-running), GPIO2 (door), and GPIO3 (ignition). The TILS sensor uses I²C SDA GPIO6, SCL GPIO7, and auto-detects the MMA8452Q at address `0x1C` or `0x1D`.

GPIO10 is reserved for the waterproof DS18B20 coolant-temperature probe.

## BLE

Service UUID: `D7F0A100-3E91-4C25-9D8A-001122334455`
Command characteristic UUID: `D7F0A101-3E91-4C25-9D8A-001122334455`
Status characteristic UUID: `D7F0A102-3E91-4C25-9D8A-001122334455`

Write UTF-8 commands to the command characteristic.

## HTTP REST API

Base URL: `http://192.168.4.1`

### `GET /api/status`

Returns JSON vehicle state:

```json
{
  "locked": true,
  "engine": false,
  "ignition": false,
  "headlights": false,
  "battery": 12.7,
  "temp": 84,
  "water_temp": 84,
  "signal": -52,
  "tiltPitch": 0.8,
  "tiltRoll": -1.1,
  "tiltValid": true,
  "tiltStatus": "safe"
}
```

### `POST /api/command`

Body: `{"command": "LOCK"}`

## Commands (BLE + HTTP)

- `STATUS` - read current state
- `LOCK` - lock doors
- `UNLOCK` - unlock doors
- `HEADLIGHT_ON` - headlights on
- `HEADLIGHT_OFF` - headlights off
- `IGNITION_ON` - ignition on
- `IGNITION_OFF` - ignition off
- `START_ENGINE` - crank starter
- `STOP_ENGINE` - stop engine

## Status broadcast

The app uses these canonical tilt fields: `tiltPitch`, `tiltRoll`, `tiltValid`, and `tiltStatus` (`safe`, `warning`, `danger`, or `unavailable`). The firmware may also provide extra raw accelerometer and legacy diagnostic fields, which the app can ignore.

GPS shown in the app is supplied by the phone. The ESP32 does not provide independent GPS unless a separate GPS receiver is added.

## Safety

All relay outputs default to their inactive HIGH state after initialisation. Vehicle 12V signals must never connect directly to an ESP32-C6 GPIO; use the appropriate divider, optocoupler or signal-conditioning circuit for each input.
