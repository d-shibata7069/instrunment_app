import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instrunment_app/telemetry/flight_telemetry.dart';
import 'package:instrunment_app/view/instrument_panel.dart';

void main() {
  FlightTelemetry frame({double? cadenceRpm = 87}) {
    return FlightTelemetry(
      receivedAt: DateTime(2026, 7, 16),
      sequence: 1842,
      simulationTimeSeconds: 42,
      latitudeDegrees: 35.170915,
      longitudeDegrees: 136.881537,
      altitudeMeters: 18.2,
      groundLevelMeters: 12.9,
      rollRadians: 0.08,
      pitchRadians: -0.04,
      yawRadians: 0.82,
      airspeedMetersPerSecond: 7.8,
      groundVelocityNorthMetersPerSecond: 7.0,
      groundVelocityEastMetersPerSecond: 1.0,
      groundVelocityDownMetersPerSecond: 0.0,
      pedalPowerWatts: 220,
      pedalCadenceRpm: cadenceRpm,
    );
  }

  testWidgets('shows the integrated flight and navigation readouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(432, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstrumentPanel(
            map: const ColoredBox(color: Color(0xFFD9E6EA)),
            frame: frame(),
            status: 'LIVE #1842',
            isStale: false,
            navigationLabel: '#01',
            navigationDistanceKilometers: 8.3,
            onRecenter: () {},
          ),
        ),
      ),
    );

    expect(find.text('LIVE #1842'), findsOneWidget);
    expect(find.text('#01  8.3 km'), findsOneWidget);
    expect(find.text('CADENCE'), findsOneWidget);
    expect(find.text('87 RPM'), findsOneWidget);
    expect(find.text('220 W'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to power when cadence is not transmitted', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(432, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstrumentPanel(
            map: const ColoredBox(color: Color(0xFFD9E6EA)),
            frame: frame(cadenceRpm: null),
            status: 'LIVE #1842',
            isStale: false,
          ),
        ),
      ),
    );

    expect(find.text('POWER'), findsOneWidget);
    expect(find.text('220 W'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a landscape desktop window without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(720, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstrumentPanel(
            map: const ColoredBox(color: Color(0xFFD9E6EA)),
            frame: frame(),
            status: 'LIVE #1842',
            isStale: false,
            navigationLabel: '#01',
            navigationDistanceKilometers: 8.3,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
