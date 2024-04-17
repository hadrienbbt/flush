import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

Future<SSHSocket> connectUnixSocket(
  String host,
  int port, {
  Duration? timeout,
}) async {
  try {
    // Bind to the Unix domain socket address
    final socket = await RawDatagramSocket.bind(
      // Use an InternetAddress with a special type to represent Unix domain sockets
      InternetAddress(host, type: InternetAddressType.unix),
      port,
    );
    socket.listen((event) {
      Datagram? dg = socket.receive();
      if (dg != null) {
        print('datagram: ${dg.data}');
      } else {
        print('event: $event');
      }
    });
    print('Socket bound to Unix domain socket: $host');
    return _SSHUnixSocket._(socket);
  } catch (e) {
    print('Error binding to Unix domain socket: $e');
    rethrow;
  }
}

class _SSHUnixSocket implements SSHSocket {
  final RawDatagramSocket _socket;
  bool isClosed = false;

  _SSHUnixSocket._(this._socket);

  @override
  Stream<Uint8List> get stream => _socket.cast<Uint8List>();

  @override
  StreamSink<List<int>> get sink => _socket.send as StreamSink<List<int>>;

  @override
  Future<void> get done => isClosed as Future<void>;

  @override
  Future<void> close() async {
    _socket.close();
    isClosed = true;
  }

  @override
  void destroy() {
    _socket.close();
    isClosed = true;
  }

  @override
  String toString() {
    final address = '${_socket.address.host}:${_socket.port}';
    return '_SSHUnixSocket($address)';
  }
}
