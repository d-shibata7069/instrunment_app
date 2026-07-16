import 'package:latlong2/latlong.dart';

class NavigationPoint {
  const NavigationPoint({
    required this.id,
    required this.label,
    required this.position,
  });

  final String id;
  final String label;
  final LatLng position;
}

class NavigationPointState {
  const NavigationPointState({this.points = const [], this.selectedId});

  final List<NavigationPoint> points;
  final String? selectedId;

  NavigationPoint? get selected {
    for (final point in points) {
      if (point.id == selectedId) {
        return point;
      }
    }
    return null;
  }
}
