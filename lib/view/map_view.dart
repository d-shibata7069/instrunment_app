import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:instrunment_app/component/flutter_map/packages.dart';
import 'package:instrunment_app/constant/static_marker.dart';
import 'package:instrunment_app/provider/map_provider.dart';
import 'package:instrunment_app/provider/telemetry_provider.dart';
import 'package:instrunment_app/telemetry/flight_telemetry.dart';
import 'package:instrunment_app/telemetry/telemetry_receiver.dart';
import 'package:instrunment_app/view/instrument_panel.dart';

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(navigationPointProvider);
    final selectedNavigationPoint = navigation.selected;
    final telemetry = ref.watch(flightTelemetryProvider);
    final currentFrame = telemetry.whenOrNull(data: (frame) => frame);
    final trail = ref.watch(telemetryTrailProvider);
    ref.watch(telemetryClockProvider);
    final isStale =
        currentFrame != null &&
        DateTime.now().difference(currentFrame.receivedAt) >
            const Duration(seconds: 2);
    final currentPosition = currentFrame == null
        ? null
        : LatLng(currentFrame.latitudeDegrees, currentFrame.longitudeDegrees);
    final navigationDistanceKilometers =
        currentPosition == null || selectedNavigationPoint == null
        ? null
        : const Distance(roundResult: false).as(
            LengthUnit.Kilometer,
            currentPosition,
            selectedNavigationPoint.position,
          );

    ref.listen<AsyncValue<FlightTelemetry>>(flightTelemetryProvider, (
      previous,
      next,
    ) {
      next.whenData((frame) {
        final existingTrail = ref.read(telemetryTrailProvider);
        ref.read(telemetryTrailProvider.notifier).add(frame);
        _followAircraft(frame, initialFix: existingTrail.isEmpty);
      });
    });

    final status = telemetry.when(
      loading: () => 'WAIT UDP${TelemetryReceiver.defaultPort}',
      error: (error, stackTrace) => 'RX ERROR',
      data: (value) => isStale ? 'LINK LOST' : 'LIVE #${value.sequence}',
    );

    return Scaffold(
      backgroundColor: InstrumentPalette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = math.min(constraints.maxWidth, 720.0);
            return Center(
              child: SizedBox(
                width: panelWidth,
                height: constraints.maxHeight,
                child: InstrumentPanel(
                  status: status,
                  frame: currentFrame,
                  isStale: isStale,
                  navigationLabel: selectedNavigationPoint?.label,
                  navigationDistanceKilometers: navigationDistanceKilometers,
                  onRecenter: currentFrame == null
                      ? null
                      : () => _followAircraft(currentFrame),
                  map: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(35.170915, 136.881537),
                      initialZoom: 10,
                      backgroundColor: const Color(0xFFD9E6EA),
                      onTap: (tapPosition, point) {
                        ref.read(navigationPointProvider.notifier).add(point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'WASAFEE/instrunment_app',
                      ),
                      MarkerLayer(
                        rotate: true,
                        markers: createInitialMarkers(context),
                      ),
                      if (currentPosition != null &&
                          selectedNavigationPoint != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                currentPosition,
                                selectedNavigationPoint.position,
                              ],
                              strokeWidth: 2,
                              color: InstrumentPalette.blue,
                              isDotted: true,
                            ),
                          ],
                        ),
                      if (trail.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: trail,
                              strokeWidth: 3,
                              color: InstrumentPalette.blue,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        rotate: true,
                        markers: [
                          for (final point in navigation.points)
                            Marker(
                              width: 64,
                              height: 58,
                              point: point.position,
                              child: _NavigationPointMarker(
                                label: point.label,
                                selected: point.id == navigation.selectedId,
                                onSelected: () {
                                  ref
                                      .read(navigationPointProvider.notifier)
                                      .select(point.id);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void _followAircraft(FlightTelemetry frame, {bool initialFix = false}) {
  final position = LatLng(frame.latitudeDegrees, frame.longitudeDegrees);
  final zoom = initialFix ? 14.0 : mapController.camera.zoom;
  final headingDegrees = frame.yawRadians * 180 / math.pi;
  mapController.moveAndRotate(position, zoom, -headingDegrees);
}

class _NavigationPointMarker extends StatelessWidget {
  const _NavigationPointMarker({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? InstrumentPalette.blue : InstrumentPalette.green;
    return Semantics(
      button: true,
      selected: selected,
      label: 'ナビポイント $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelected,
        onLongPress: onSelected,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(
              Icons.navigation,
              color: color,
              size: selected ? 27 : 22,
              shadows: const [Shadow(color: Colors.white, blurRadius: 3)],
            ),
          ],
        ),
      ),
    );
  }
}
