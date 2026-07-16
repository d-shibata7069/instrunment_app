import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:instrunment_app/component/flutter_map/packages.dart';
import 'package:instrunment_app/model/navigation_point.dart';

final navigationPointProvider =
    StateNotifierProvider<NavigationPointNotifier, NavigationPointState>(
      (ref) => NavigationPointNotifier(),
    );

final mapController = MapController();

class NavigationPointNotifier extends StateNotifier<NavigationPointState> {
  NavigationPointNotifier() : super(const NavigationPointState());

  int _nextNumber = 1;

  NavigationPoint add(LatLng position) {
    final number = _nextNumber++;
    final point = NavigationPoint(
      id: 'navigation-$number',
      label: '#${number.toString().padLeft(2, '0')}',
      position: position,
    );
    state = NavigationPointState(
      points: List.unmodifiable([...state.points, point]),
      selectedId: point.id,
    );
    return point;
  }

  void select(String id) {
    if (!state.points.any((point) => point.id == id)) {
      return;
    }
    state = NavigationPointState(points: state.points, selectedId: id);
  }

  void clear() {
    _nextNumber = 1;
    state = const NavigationPointState();
  }
}
