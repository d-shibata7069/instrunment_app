import 'dart:async';
import 'dart:io';

import 'flight_telemetry.dart';

/// Receives versioned FEE telemetry from any sender on the local network.
class TelemetryReceiver {
  TelemetryReceiver({this.port = defaultPort});

  static const int defaultPort = 5503;

  final int port;
  final StreamController<FlightTelemetry> _controller =
      StreamController<FlightTelemetry>.broadcast();

  RawDatagramSocket? _socket;
  bool _disposed = false;
  int rejectedDatagrams = 0;

  Stream<FlightTelemetry> get stream => _controller.stream;

  Future<void> start() async {
    if (_socket != null || _disposed) {
      return;
    }

    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
    );
    if (_disposed) {
      socket.close();
      return;
    }

    _socket = socket;
    socket.listen(
      (event) {
        if (event != RawSocketEvent.read) {
          return;
        }
        Datagram? datagram;
        while ((datagram = socket.receive()) != null) {
          try {
            _controller.add(FlightTelemetry.fromDatagram(datagram!.data));
          } on FormatException {
            rejectedDatagrams += 1;
          }
        }
      },
      onError: _controller.addError,
      onDone: _controller.close,
    );
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _socket?.close();
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
  }
}
