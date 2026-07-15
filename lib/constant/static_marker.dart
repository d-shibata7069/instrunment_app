import 'package:flutter/material.dart';
import 'package:instrunment_app/component/flutter_map/packages.dart';

// 地図に初めから表示しておくマーカーを定義
List<Marker> createInitialMarkers(BuildContext context) {
  return [
    // ここにマーカーを追加
    Marker(
      width: 20.0,
      height: 20.0,
      point: LatLng(35.29479295353468, 136.25492870156955),
      child: GestureDetector(
        onLongPress: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ピンの詳細'),
            content: const Text('鳥人間コンテスト会場'),
            actions: <Widget>[
              TextButton(
                child: const Text('閉じる'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        child: Icon(
          Icons.circle,
          color: Colors.red,
          size: 20,
        ),
      ),
    ),
  ];
}
