import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l200_app/screens/dashboard_screen.dart';
import 'package:l200_app/services/ble_service.dart';

void main() {
  testWidgets('dashboard shows the prepared vehicle controls', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = BleVehicleService();
    await tester.pumpWidget(
      MaterialApp(home: DashboardScreen(service: service, autoStart: false)),
    );

    expect(find.byKey(const Key('header-stripe')), findsOneWidget);
    expect(find.text('VOLTAGE'), findsOneWidget);
    expect(find.text('12.6V'), findsOneWidget);
    expect(find.text('WATER'), findsOneWidget);
    expect(find.text('82°C'), findsOneWidget);
    expect(find.text('SIGNAL'), findsOneWidget);
    expect(find.text('UNLOCK'), findsOneWidget);
    expect(find.text('LIGHTS ON'), findsOneWidget);
    expect(find.text('IGNITION ON'), findsOneWidget);
    expect(find.text('START ENGINE'), findsOneWidget);

    service.dispose();
  });
}
