# L200 Nexus App

Flutter dashboard for the L200 Nexus ACP vehicle controller.

## Features

- BLE and Wi-Fi vehicle control
- Lock, unlock, ignition, starter, and headlights
- Live battery, temperature, signal, and vehicle status
- Live TILS tilt pitch/roll and Safe/Warning/Danger status
- Persistent level-position tilt calibration
- GPS location display

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
