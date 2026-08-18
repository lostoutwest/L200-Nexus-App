# L200 ESP32 V2 Protocol

The ESP32 runs both BLE and WiFi AP simultaneously.

WiFi AP: `L200-NEXUS` (password: `L200Nexus`)
BLE name: `L200-NEXUS`

## Canonical firmware pinout

The standalone firmware uses active-low relay outputs on GPIO16 (lock), GPIO17 (unlock), GPIO18 (ignition), GPIO19 (starter), and GPIO21 (headlights). RGB data is GPIO22. Vehicle inputs are GPIO34 (engine), GPIO35 (battery), GPIO32 (door), and GPIO33 (ignition). The TILS sensor uses I²C SDA GPIO25, SCL GPIO26, address `0x53`.

## BLE (V1 backward compatible)

Service UUID: `D7F0A100-3E91-4C25-9D8A-001122334455`
Command characteristic UUID: `D7F0A101-3E91-4C25-9D8A-001122334455`
Status characteristic UUID: `D7F0A102-3E91-4C25-9D8A-001122334455`

Write UTF-8 commands to the characteristic.

## HTTP REST API (V2)

Base URL: `http://192.168.4.1`

### `GET /api/status`

Returns JSON vehicle state (poll every 1s):

```json
{
  "locked": true,
  "engine": false,
  "headlights": false,
  "battery": 12.7,
  "temp": 84,
  "signal": -52
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
- `CALIBRATE_TILT` - save the current still, level position as the tilt zero point

## Centralised action functions (ESP32 firmware)

All transports call the same functions:

```cpp
void lockDoors();
void unlockDoors();
void ignitionOn();
void ignitionOff();
void startEngine();
void stopEngine();
void headlights(bool state);
```

## Status broadcast

ESP32 sends JSON status every second on both transports.

Tilt status fields are included when the sensor is available: `tiltPitch`, `tiltRoll`, `tiltValid`, and `tiltStatus` (`safe`, `warning`, `danger`, or `unavailable`). Send `CALIBRATE_TILT` while the vehicle is parked level and still to save the current position as level.
The app reads this to update the live dashboard.

GPS shown in the app is supplied by the phone. The ESP32 does not provide independent GPS unless a separate GPS receiver is added.

## Safety

All outputs default to safe/off state after reset or watchdog.
Firmware reports sensed state where feedback exists, not echoed state.
