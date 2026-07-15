import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:instrunment_app/component/flutter_map/packages.dart';

final markerProvider = StateNotifierProvider<MarkerNotifier, List<Marker>>(
  (ref) => MarkerNotifier(),
);

// MapControllerのインスタンス作成
final MapController mapController = MapController();

class MarkerNotifier extends StateNotifier<List<Marker>> {
  MarkerNotifier() : super([]);

  void addMarker(LatLng latlng, BuildContext context) {
    // markersリストを毎回作り直さないと状態が更新されない
    state = [
      ...state,
      Marker(
        width: 30.0,
        height: 50.0,
        point: latlng,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            mapController.move(latlng, mapController.camera.zoom);
          },
          onLongPress: () {
            _showAlert(latlng, context);
          },
          child: const Icon(Icons.location_on, color: Colors.blue, size: 50),
        ),
      ),
    ];
  }

  void _showAlert(LatLng latlng, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ピンの位置'),
        content: Text('緯度: ${latlng.latitude}, 経度: ${latlng.longitude}'),
        actions: <Widget>[
          TextButton(
            child: const Text('閉じる'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// class MarkerWidget extends StatefulWidget {
//   @override
//   _MarkerWidgetState createState() => _MarkerWidgetState();
// }

// class _MarkerWidgetState extends State<MarkerWidget>
//     with TickerProviderStateMixin {
//   late final AnimatedMapController _animatedMapController;

//   @override
//   void initState() {
//     super.initState();
//     _animatedMapController = AnimatedMapController(vsync: this);
//   }

//   void addMarker(LatLng latlng) {
//     final marker = Marker(
//       width: 30.0,
//       height: 30.0,
//       point: latlng,
//       child: GestureDetector(
//         onTap: () {
//           _animatedMapController.animateTo(dest: latlng);
//         },
//         child: const Icon(
//           Icons.location_on,
//           color: Colors.blue,
//           size: 50,
//         ),
//       ),
//     );

//     context.read(markerProvider.notifier).addMarker(marker);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(); // 実際のUIをここに構築します
//   }
// }
