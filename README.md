# L200 Nexus App

Flutter dashboard for the L200 Nexus ACP vehicle controller.

## Features

- BLE and Wi-Fi vehicle control
- Lock, unlock, ignition, starter, and headlights
- Live battery, temperature, signal, and vehicle status
- Live TILS tilt pitch/roll and Safe/Warning/Danger status
- Persistent level-position tilt calibration
- GPS location display

## Canonical hardware pinout

The companion ESP32 firmware uses this current configuration:

| Function | ESP32 pin |
| :--- | :---: |
| Lock relay (active-low) | GPIO16 |
| Unlock relay (active-low) | GPIO17 |
| Ignition relay (active-low) | GPIO18 |
| Starter relay (active-low) | GPIO19 |
| Headlights relay (active-low) | GPIO21 |
| WS2812B RGB data | GPIO22 |
| Engine-running input | GPIO34 |
| Battery-sense input | GPIO35 |
| Door-trigger input | GPIO32 |
| Ignition input | GPIO33 |
| TILS I²C SDA | GPIO25 |
| TILS I²C SCL | GPIO26 |

Relay outputs are inactive HIGH. The ESP32 has no onboard GPS receiver; the dashboard’s GPS comes from the phone, while the operating system may improve its position using nearby Wi-Fi or Bluetooth signals.

## Development

```text
flutter pub get
flutter analyze
flutter test
flutter run
```

The companion ESP32 firmware is maintained separately in
[L200-Nexus-Firmware](https://github.com/lostoutwest/L200-Nexus-Firmware).

The app expects the ESP32 to advertise as `L200-NEXUS` and uses the BLE and
Wi-Fi protocol documented in [ESP32_PROTOCOL.md](ESP32_PROTOCOL.md).
