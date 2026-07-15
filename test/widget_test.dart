import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:instrunment_app/telemetry/flight_telemetry.dart';

void main() {
  Uint8List datagram({
    String schema = FlightTelemetry.schema,
    int version = FlightTelemetry.schemaVersion,
    double latitude = 35.0,
  }) {
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'schema': schema,
          'version': version,
          'sequence': 42,
          'simulationTime_s': 12.5,
          'position': {
            'latitude_deg': latitude,
            'longitude_deg': 139.0,
            'altitude_m': 18.2,
            'groundLevel_m': 16.0,
          },
          'attitude': {'roll_rad': 0.1, 'pitch_rad': -0.2, 'yaw_rad': 1.5},
          'motion': {
            'airspeed_mps': 7.6,
            'groundVelocityNED_mps': [7.0, 1.0, 0.0],
          },
          'pedaling': {'power_W': 220.0},
        }),
      ),
    );
  }

  test('parses a version 1 telemetry datagram', () {
    final frame = FlightTelemetry.fromDatagram(datagram());

    expect(frame.sequence, 42);
    expect(frame.latitudeDegrees, 35.0);
    expect(frame.airspeedMetersPerSecond, 7.6);
    expect(frame.groundVelocityNorthMetersPerSecond, 7.0);
    expect(frame.pedalPowerWatts, 220.0);
  });

  test('rejects an unknown schema version', () {
    expect(
      () => FlightTelemetry.fromDatagram(datagram(version: 2)),
      throwsFormatException,
    );
  });

  test('rejects an out-of-range latitude', () {
    expect(
      () => FlightTelemetry.fromDatagram(datagram(latitude: 91)),
      throwsFormatException,
    );
  });

  test('rejects invalid UTF-8 JSON', () {
    expect(
      () => FlightTelemetry.fromDatagram(Uint8List.fromList([0xff])),
      throwsFormatException,
    );
  });
}
