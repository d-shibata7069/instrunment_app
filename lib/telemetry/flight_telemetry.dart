import 'dart:convert';
import 'dart:typed_data';

/// One versioned, validated telemetry frame sent by the private FEE.
class FlightTelemetry {
  const FlightTelemetry({
    required this.receivedAt,
    required this.sequence,
    required this.simulationTimeSeconds,
    required this.latitudeDegrees,
    required this.longitudeDegrees,
    required this.altitudeMeters,
    required this.groundLevelMeters,
    required this.rollRadians,
    required this.pitchRadians,
    required this.yawRadians,
    required this.airspeedMetersPerSecond,
    required this.groundVelocityNorthMetersPerSecond,
    required this.groundVelocityEastMetersPerSecond,
    required this.groundVelocityDownMetersPerSecond,
    required this.pedalPowerWatts,
  });

  static const String schema = 'wasafee.flight-telemetry';
  static const int schemaVersion = 1;

  /// Local receipt time. This is not supplied by the simulator.
  final DateTime receivedAt;
  final int sequence;
  final double simulationTimeSeconds;
  final double latitudeDegrees;
  final double longitudeDegrees;
  final double altitudeMeters;
  final double groundLevelMeters;
  final double rollRadians;
  final double pitchRadians;
  final double yawRadians;
  final double airspeedMetersPerSecond;
  final double groundVelocityNorthMetersPerSecond;
  final double groundVelocityEastMetersPerSecond;
  final double groundVelocityDownMetersPerSecond;
  final double pedalPowerWatts;

  static FlightTelemetry fromDatagram(Uint8List bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    } on Object catch (error) {
      throw FormatException('Telemetry is not valid UTF-8 JSON.', error);
    }
    return fromJson(_asMap(decoded, r'$'));
  }

  static FlightTelemetry fromJson(Map<String, dynamic> json) {
    if (json['schema'] != schema) {
      throw const FormatException('Unsupported telemetry schema.');
    }
    if (_asInteger(json['version'], r'$.version') != schemaVersion) {
      throw const FormatException('Unsupported telemetry schema version.');
    }

    final position = _asMap(json['position'], r'$.position');
    final attitude = _asMap(json['attitude'], r'$.attitude');
    final motion = _asMap(json['motion'], r'$.motion');
    final pedaling = _asMap(json['pedaling'], r'$.pedaling');
    final velocity = _asVector3(
      motion['groundVelocityNED_mps'],
      r'$.motion.groundVelocityNED_mps',
    );

    final latitude =
        _asNumber(position['latitude_deg'], r'$.position.latitude_deg');
    final longitude =
        _asNumber(position['longitude_deg'], r'$.position.longitude_deg');
    if (latitude < -90 || latitude > 90) {
      throw const FormatException('Latitude is outside -90..90 degrees.');
    }
    if (longitude < -180 || longitude > 180) {
      throw const FormatException('Longitude is outside -180..180 degrees.');
    }

    return FlightTelemetry(
      receivedAt: DateTime.now(),
      sequence: _asInteger(json['sequence'], r'$.sequence'),
      simulationTimeSeconds:
          _asNumber(json['simulationTime_s'], r'$.simulationTime_s'),
      latitudeDegrees: latitude,
      longitudeDegrees: longitude,
      altitudeMeters:
          _asNumber(position['altitude_m'], r'$.position.altitude_m'),
      groundLevelMeters:
          _asNumber(position['groundLevel_m'], r'$.position.groundLevel_m'),
      rollRadians: _asNumber(attitude['roll_rad'], r'$.attitude.roll_rad'),
      pitchRadians: _asNumber(attitude['pitch_rad'], r'$.attitude.pitch_rad'),
      yawRadians: _asNumber(attitude['yaw_rad'], r'$.attitude.yaw_rad'),
      airspeedMetersPerSecond:
          _asNumber(motion['airspeed_mps'], r'$.motion.airspeed_mps'),
      groundVelocityNorthMetersPerSecond: velocity[0],
      groundVelocityEastMetersPerSecond: velocity[1],
      groundVelocityDownMetersPerSecond: velocity[2],
      pedalPowerWatts: _asNumber(pedaling['power_W'], r'$.pedaling.power_W'),
    );
  }

  static Map<String, dynamic> _asMap(Object? value, String path) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('$path must be an object.');
    }
    return value;
  }

  static List<double> _asVector3(Object? value, String path) {
    if (value is! List<dynamic> || value.length != 3) {
      throw FormatException('$path must contain exactly three numbers.');
    }
    return List<double>.generate(
      3,
      (index) => _asNumber(value[index], '$path[$index]'),
      growable: false,
    );
  }

  static double _asNumber(Object? value, String path) {
    if (value is! num) {
      throw FormatException('$path must be a number.');
    }
    final result = value.toDouble();
    if (!result.isFinite) {
      throw FormatException('$path must be finite.');
    }
    return result;
  }

  static int _asInteger(Object? value, String path) {
    if (value is! num || !value.isFinite || value != value.roundToDouble()) {
      throw FormatException('$path must be an integer.');
    }
    return value.toInt();
  }
}
