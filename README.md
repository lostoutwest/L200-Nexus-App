# L200 Nexus App

Flutter dashboard for the L200 Nexus ACP vehicle controller.

## Features

- BLE and Wi-Fi vehicle control
- Lock, unlock, ignition, starter, and headlights
- Live battery, temperature, signal, and vehicle status
- Live TILS tilt pitch/roll and Safe/Warning/Danger status
- GPS location display

## Canonical hardware pinout

The companion firmware now targets an ESP32-C6 / ESP32-C6-MINI-1-class controller:

| Function | ESP32-C6 pin |
| :--- | :---: |
| Lock relay (active-low) | GPIO18 |
| Unlock relay (active-low) | GPIO19 |
| Ignition relay (active-low) | GPIO20 |
| Starter relay (active-low) | GPIO21 |
| Headlights relay (active-low) | GPIO22 |
| SM16703P RGB data | GPIO23 |
| Battery-sense ADC | GPIO0 |
| Engine-running input | GPIO1 |
| Door-trigger input | GPIO2 |
| Ignition input | GPIO3 |
| TILS I²C SDA | GPIO6 |
| TILS I²C SCL | GPIO7 |
| Reserved DS18B20 coolant probe | GPIO10 |

The MMA8452Q tilt sensor is detected at `0x1C` or `0x1D`.

Relay outputs are inactive HIGH. Vehicle 12V signals must be conditioned before reaching an ESP32-C6 GPIO. The ESP32 has no onboard GPS receiver; the dashboard’s GPS comes from the phone.

## Development

```text
flutter pub get
flutter analyze
flutter test
flutter run
```

The companion ESP32 firmware is maintained separately in
[L200-Nexus-Firmware](https://github.com/lostoutwest/L200-Nexus-Firmware).

The app expects the ESP32 to advertise as `L200-NEXUS` and uses the BLE and Wi-Fi protocol documented in [ESP32_PROTOCOL.md](ESP32_PROTOCOL.md).
