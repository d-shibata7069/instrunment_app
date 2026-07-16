import 'package:flutter_test/flutter_test.dart';
import 'package:instrunment_app/component/flutter_map/packages.dart';
import 'package:instrunment_app/provider/map_provider.dart';

void main() {
  test('adds, numbers, and selects navigation points', () {
    final notifier = NavigationPointNotifier();

    final first = notifier.add(const LatLng(35.0, 136.0));
    final second = notifier.add(const LatLng(35.1, 136.1));

    expect(first.label, '#01');
    expect(second.label, '#02');
    expect(notifier.state.points, hasLength(2));
    expect(notifier.state.selected, same(second));

    notifier.select(first.id);
    expect(notifier.state.selected, same(first));
  });

  test('ignores an unknown navigation point selection', () {
    final notifier = NavigationPointNotifier();
    final point = notifier.add(const LatLng(35.0, 136.0));

    notifier.select('unknown');

    expect(notifier.state.selected, same(point));
  });

  test('starts numbering again after navigation points are cleared', () {
    final notifier = NavigationPointNotifier();
    notifier.add(const LatLng(35.0, 136.0));

    notifier.clear();
    final point = notifier.add(const LatLng(35.1, 136.1));

    expect(point.label, '#01');
  });
}
