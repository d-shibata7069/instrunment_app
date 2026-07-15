import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../telemetry/flight_telemetry.dart';
import '../telemetry/telemetry_receiver.dart';

final flightTelemetryProvider =
    StreamProvider.autoDispose<FlightTelemetry>((ref) async* {
  final receiver = TelemetryReceiver();
  ref.onDispose(receiver.dispose);

  await receiver.start();
  yield* receiver.stream;
});

final telemetryTrailProvider =
    StateNotifierProvider<TelemetryTrailNotifier, List<LatLng>>(
  (ref) => TelemetryTrailNotifier(),
);

class TelemetryTrailNotifier extends StateNotifier<List<LatLng>> {
  TelemetryTrailNotifier() : super(const []);

  static const int maximumPoints = 600;

  void add(FlightTelemetry frame) {
    final point = LatLng(frame.latitudeDegrees, frame.longitudeDegrees);
    if (state.isNotEmpty && state.last == point) {
      return;
    }

    final next = [...state, point];
    state = next.length <= maximumPoints
        ? List.unmodifiable(next)
        : List.unmodifiable(next.sublist(next.length - maximumPoints));
  }

  void clear() {
    state = const [];
  }
}
