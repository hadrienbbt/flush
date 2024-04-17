import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dartssh2/dartssh2.dart';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

Future<SSHSocket> connectWebSocket(
  String host,
  int port, {
  Duration? timeout,
}) async {
  Random r = Random();
  String key = base64.encode(List<int>.generate(8, (_) => r.nextInt(256)));
  WebSocketChannel.signKey(key);

  final url = Uri.parse('wss://$host:$port');
  final socket = WebSocketChannel.connect(url);
  final streamController = StreamController<List<int>>();

  socket.stream.listen((message) {
    print('message: $message');
    streamController.add(message);
  }, onDone: () {
    streamController.close();
  }, onError: (error) {
    if (error is WebSocketChannelException) {
      print('error: ${error.message}');
      print('inner error: ${error.inner}');
    } else {
      print('error: $error');
    }
    print('error: $error');
    streamController.addError(error);
  }, cancelOnError: true);

  return _SSHWebSocket._(socket, streamController);
}

class _SSHWebSocket implements SSHSocket {
  final WebSocketChannel _socket;
  final StreamController<List<int>> _streamController;

  _SSHWebSocket._(this._socket, this._streamController);

  @override
  Stream<Uint8List> get stream =>
      _streamController.stream.map((data) => Uint8List.fromList(data));

  @override
  StreamSink<List<int>> get sink => _ListIntToUtf8StringSink(_socket.sink);

  @override
  Future<void> get done => _socket.sink.done;

  @override
  Future<void> close() async {
    await _socket.sink.close();
  }

  @override
  void destroy() {
    _socket.sink.close();
    _streamController.close();
  }
}

class _ListIntToUtf8StringSink implements StreamSink<List<int>> {
  final WebSocketSink _sink;

  _ListIntToUtf8StringSink(this._sink);

  @override
  void add(List<int> data) {
    print('add: $data');
    _sink.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  Future<void> close() => _sink.close();

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.forEach(add);

  @override
  Future<void> get done => _sink.done;
}
