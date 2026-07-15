import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:instrunment_app/component/flutter_map/packages.dart';
import 'package:instrunment_app/constant/static_marker.dart';
import 'package:instrunment_app/provider/map_provider.dart';
import 'package:instrunment_app/provider/telemetry_provider.dart';
import 'package:instrunment_app/telemetry/flight_telemetry.dart';
import 'package:instrunment_app/telemetry/telemetry_receiver.dart';

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(markerProvider);
    final telemetry = ref.watch(flightTelemetryProvider);
    final currentFrame = telemetry.whenOrNull(data: (frame) => frame);
    final trail = ref.watch(telemetryTrailProvider);

    ref.listen<AsyncValue<FlightTelemetry>>(
      flightTelemetryProvider,
      (previous, next) {
        next.whenData(ref.read(telemetryTrailProvider.notifier).add);
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(35.170915, 136.881537),
              initialZoom: 10,
              onTap: (tapPosition, point) {
                ref.read(markerProvider.notifier).addMarker(point, context);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(markers: createInitialMarkers(context)),
              MarkerLayer(markers: markers),
              if (trail.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trail,
                      strokeWidth: 3,
                      color: Colors.deepOrange,
                    ),
                  ],
                ),
              if (currentFrame != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 48,
                      height: 48,
                      point: LatLng(
                        currentFrame.latitudeDegrees,
                        currentFrame.longitudeDegrees,
                      ),
                      child: Transform.rotate(
                        angle: currentFrame.yawRadians,
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.deepOrange,
                          size: 42,
                          shadows: [
                            Shadow(color: Colors.white, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: _TelemetryStatus(
                telemetry: telemetry,
                frame: currentFrame,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryStatus extends StatelessWidget {
  const _TelemetryStatus({required this.telemetry, required this.frame});

  final AsyncValue<FlightTelemetry> telemetry;
  final FlightTelemetry? frame;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = telemetry.when(
      loading: () => 'UDP ${TelemetryReceiver.defaultPort} で待機中',
      error: (error, stackTrace) => '受信開始エラー',
      data: (value) => '受信中  #${value.sequence}',
    );

    return Card(
      margin: const EdgeInsets.all(12),
      color: colorScheme.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (frame != null) ...[
                Text(
                  '緯度 ${frame!.latitudeDegrees.toStringAsFixed(5)}°  '
                  '経度 ${frame!.longitudeDegrees.toStringAsFixed(5)}°',
                ),
                Text(
                  '高度 ${frame!.altitudeMeters.toStringAsFixed(1)} m  '
                  '対気速度 '
                  '${frame!.airspeedMetersPerSecond.toStringAsFixed(1)} m/s',
                ),
                Text(
                  'ペダル出力 ${frame!.pedalPowerWatts.toStringAsFixed(0)} W',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
