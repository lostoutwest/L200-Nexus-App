import 'package:flutter/material.dart';

import '../models/vehicle_state.dart';
import '../services/vehicle_service.dart';
import '../services/service_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/analog_gauge.dart';
import '../widgets/dash_switch_button.dart';
import '../widgets/connection_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({this.service, this.autoStart = true, super.key});

  final VehicleService? service;
  final bool autoStart;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final VehicleService _service;
  late final bool _ownsService;
  final LocationService _locationService = LocationService();
  AnimationController? _crankAnimation;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? VehicleServiceProvider();
    if (widget.autoStart) _service.initialize();
    _service.addListener(_onServiceUpdate);
    _locationService.addListener(_onLocationChanged);
    _locationService.start();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    if (_ownsService) _service.dispose();
    _locationService.removeListener(_onLocationChanged);
    _locationService.dispose();
    _crankAnimation?.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    setState(() {
      _handleEnginePhase();
    });
  }

  void _handleEnginePhase() {
    if (_service.enginePhase == EnginePhase.cranking) {
      _crankAnimation ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      if (!_crankAnimation!.isAnimating) {
        _crankAnimation!.repeat(reverse: true);
      }
    } else {
      _crankAnimation?.stop();
      _crankAnimation?.reset();
    }
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 92,
        automaticallyImplyLeading: false,
        flexibleSpace: const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: _HeaderStripe(),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF17150F), AppColors.black, Color(0xFF100D07)],
            stops: [0, 0.42, 1],
          ),
        ),
        child: AnimatedBuilder(
          animation: _service,
          builder: (context, _) {
            final vehicle = _service.vehicleState;
            final controlsEnabled = _service.isConnected;
            final phase = _service.enginePhase;

            return SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _vehicleImage(),
                  const SizedBox(height: 16),
                  _gaugesCard(vehicle),
                  const SizedBox(height: 12),
                  _tiltCard(vehicle, controlsEnabled),
                  const SizedBox(height: 12),
                  _controlButtons(vehicle, controlsEnabled, phase),
                  const SizedBox(height: 12),
                  _engineControl(controlsEnabled, phase),
                  const SizedBox(height: 12),
                  _LocationCard(locationService: _locationService),
                  const SizedBox(height: 22),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _vehicleImage() {
    final provider = _service is VehicleServiceProvider ? _service : null;
    final bleConnected = provider?.bleService?.isConnected ?? false;
    final wifiConnected = provider?.wifiService?.isConnected ?? false;

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: AppColors.metallicGold,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.16),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/l200.png',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.42),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () {
                  if (provider is VehicleServiceProvider) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ConnectionSheet(provider: provider),
                    );
                  }
                },
                child: _ConnectionStatus(
                  bleConnected: bleConnected,
                  wifiConnected: wifiConnected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gaugesCard(VehicleState vehicle) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        gradient: AppColors.blackShimmer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnalogGauge(
                  title: 'Water',
                  value: vehicle.waterTemperature,
                  minimum: 40,
                  maximum: 120,
                  unit: '°C',
                  majorDivisions: 4,
                  warningFrom: 100,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnalogGauge(
                  title: 'Engine',
                  value: vehicle.temperatureCelsius,
                  minimum: 40,
                  maximum: 120,
                  unit: '°C',
                  majorDivisions: 4,
                  warningFrom: 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AnalogGauge(
                  title: 'Voltage',
                  value: vehicle.batteryVoltage,
                  minimum: 8,
                  maximum: 16,
                  unit: 'V',
                  majorDivisions: 4,
                  decimalPlaces: 1,
                  warningFrom: 15,
                  warningUntil: 10,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnalogGauge(
                  title: 'Signal',
                  value: vehicle.signalRssi.toDouble(),
                  minimum: -100,
                  maximum: 0,
                  unit: ' dBm',
                  majorDivisions: 5,
                  decimalPlaces: 0,
                  warningUntil: -80,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tiltCard(VehicleState vehicle, bool controlsEnabled) {
    final status = vehicle.tiltStatus.toLowerCase();
    final statusColor = switch (status) {
      'safe' => const Color(0xFF6FA35C),
      'warning' => Colors.amber,
      'danger' => Colors.redAccent,
      _ => const Color(0xFF9E967D),
    };
    final statusLabel = status == 'unavailable'
        ? 'SENSOR UNAVAILABLE'
        : status.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.blackShimmer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.58)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.screen_rotation_alt, size: 20, color: statusColor),
              const SizedBox(width: 8),
              const Text(
                'VEHICLE TILT',
                style: TextStyle(
                  color: AppColors.paleGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tiltValue('PITCH', vehicle.tiltPitch)),
              Transform.rotate(
                angle: vehicle.tiltRoll * 3.1415926535 / 180,
                child: Icon(Icons.directions_car, size: 46, color: statusColor),
              ),
              Expanded(child: _tiltValue('ROLL', vehicle.tiltRoll)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controlsEnabled && vehicle.tiltValid ? _calibrateTilt : null,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('CALIBRATE LEVEL POSITION'),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Park level, keep still, then calibrate.',
            style: TextStyle(color: Color(0xFF9E967D), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _tiltValue(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9E967D), fontSize: 10, letterSpacing: 1.2)),
        const SizedBox(height: 3),
        Text(
          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}°',
          style: const TextStyle(color: Color(0xFFF2E9CD), fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Future<void> _calibrateTilt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibrate tilt sensor?'),
        content: const Text(
          'Park the vehicle on level ground and keep it still. The current position will be saved as level.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('CALIBRATE')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _service.calibrateTilt();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tilt sensor calibrated and saved.')),
    );
  }

  Widget _controlButtons(
    VehicleState vehicle,
    bool controlsEnabled,
    EnginePhase phase,
  ) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: DashSwitchButton(
              label: vehicle.locked ? 'UNLOCK' : 'LOCK',
              icon: vehicle.locked ? Icons.lock_open : Icons.lock,
              glowColor: vehicle.locked
                  ? const Color(0xFF51A35B)
                  : const Color(0xFFD7463F),
              onPressed: controlsEnabled
                  ? () {
                    if (vehicle.locked) {
                      _service.unlockDoors();
                    } else {
                      _service.lockDoors();
                    }
                  }
                  : null,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: DashSwitchButton(
              label: vehicle.headlightsOn ? 'LIGHTS OFF' : 'LIGHTS ON',
              icon: Icons.lightbulb_outline,
              glowColor: vehicle.headlightsOn
                  ? const Color(0xFFFFD83D)
                  : null,
              onPressed: controlsEnabled
                  ? () => _service.headlights(!vehicle.headlightsOn)
                  : null,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: DashSwitchButton(
              label: phase == EnginePhase.running
                  ? 'IGNITION OFF'
                  : 'IGNITION ON',
              icon: Icons.power_settings_new,
              glowColor: phase == EnginePhase.running
                  ? const Color(0xFF6FA35C)
                  : null,
              onPressed: controlsEnabled
                  ? () {
                    if (phase == EnginePhase.running) {
                      _service.ignitionOff();
                    } else {
                      _service.ignitionOn();
                    }
                  }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _engineControl(bool controlsEnabled, EnginePhase phase) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: controlsEnabled ? AppColors.metallicGold : AppColors.blackShimmer,
        borderRadius: BorderRadius.circular(21),
        border: controlsEnabled
            ? null
            : Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: AppColors.black,
          child: InkWell(
            onTap: controlsEnabled ? _handleEngineAction : null,
            child: Container(
              height: 72,
              alignment: Alignment.center,
              child: phase == EnginePhase.cranking
                  ? AnimatedBuilder(
                      animation: _crankAnimation!,
                      builder: (context, _) {
                        final flash = _crankAnimation!.value;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Color.lerp(
                                Colors.orangeAccent,
                                Colors.yellowAccent,
                                flash,
                              )!,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CRANKING',
                              style: TextStyle(
                                color: Color.lerp(
                                  Colors.orangeAccent,
                                  Colors.yellowAccent,
                                  flash,
                                ),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          phase == EnginePhase.running
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline,
                          color: phase == EnginePhase.running
                              ? Colors.redAccent
                              : const Color(0xFF6FA35C),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          phase == EnginePhase.running
                              ? 'STOP ENGINE'
                              : 'START ENGINE',
                          style: TextStyle(
                            color: phase == EnginePhase.running
                                ? Colors.redAccent
                                : const Color(0xFF6FA35C),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleEngineAction() {
    final phase = _service.enginePhase;
    if (phase == EnginePhase.running) {
      _service.stopEngine();
    } else {
      _service.startEngine();
    }
  }
}

class _HeaderStripe extends StatelessWidget {
  const _HeaderStripe();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(
        child: SizedBox.expand(
          child: Transform.translate(
            offset: Offset(-constraints.maxWidth * 0.14, 0),
            child: Transform.scale(
              scale: 2.34,
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.hardEdge,
                child: Image.asset(
                  'assets/images/header_stripe.png',
                  key: const Key('header-stripe'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({
    required this.bleConnected,
    required this.wifiConnected,
  });

  final bool bleConnected;
  final bool wifiConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth,
            size: 20,
            color: bleConnected ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.wifi,
            size: 20,
            color: wifiConnected ? Colors.greenAccent : Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.locationService});

  final LocationService locationService;

  @override
  Widget build(BuildContext context) {
    final pos = locationService.lastPosition;
    final error = locationService.error;

    return AnimatedBuilder(
      animation: locationService,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.blackShimmer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.45),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.gps_fixed,
                    size: 18,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GPS LOCATION',
                    style: TextStyle(
                      color: AppColors.paleGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  if (pos != null)
                    Text(
                      '±${pos.accuracy.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        color: Color(0xFF9E967D),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (error != null)
                Text(
                  error,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                )
              else if (pos == null)
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Acquiring GPS fix...',
                      style: TextStyle(color: Color(0xFF9E967D), fontSize: 13),
                    ),
                  ],
                )
              else ...[
                Row(
                  children: [
                    const Icon(Icons.my_location, size: 14, color: Color(0xFF9E967D)),
                    const SizedBox(width: 6),
                    Text(
                      '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: Color(0xFFF2E9CD),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.speed, size: 14, color: Color(0xFF9E967D)),
                    const SizedBox(width: 6),
                    Text(
                      '${pos.speed.toStringAsFixed(1)} km/h  ·  ${pos.heading.toStringAsFixed(0)}° heading',
                      style: const TextStyle(
                        color: Color(0xFF9E967D),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
