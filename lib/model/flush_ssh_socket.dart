import 'dart:async';
import 'dart:typed_data';

import 'package:flush/model/ssh_unix_socket.dart';
import 'package:flush/model/ssh_web_socket.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:dartssh2/dartssh2.dart';
// ignore: implementation_imports
import 'package:dartssh2/src/socket/ssh_socket_io.dart'
    if (dart.library.js) 'package:dartssh2/src/socket/ssh_socket_js.dart';

abstract class FlushSSHSocket {
  static Future<SSHSocket> connect(
    String host,
    int port, {
    Duration? timeout,
  }) async {
    if (kIsWeb) {
      // return await connectUnixSocket(host, port);
      return await connectWebSocket(host, port);
    } else {
      return await connectNativeSocket(host, port);
    }
  }

  Stream<Uint8List> get stream;

  StreamSink<List<int>> get sink;

  /// A future that will complete when the consumer closes, or when an error occurs.
  Future<void> get done;

  /// Closes the socket, returning the same future as [done].
  Future<void> close();

  void destroy();
}
