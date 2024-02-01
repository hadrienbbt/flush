import 'package:flutter/foundation.dart';
import 'package:flush/model/credentials.dart';
import 'package:flush/model/private_key.dart';
import 'package:flush/model/host.dart';

class LoginController extends ChangeNotifier {
  Host? _host;
  PrivateKey? _privateKey;

  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectionState;

  Host? get host {
    return _host;
  }

  String get currentHostId {
    return _host?.id ?? 'no-host';
  }

  void setHost(Host? host) {
    _host = host;
    notifyListeners();
  }

  PrivateKey? get privateKey {
    return _privateKey;
  }

  void setPrivateKey(PrivateKey? key) {
    _privateKey = key;
    notifyListeners();
  }

  Credentials? get credentials {
    if (_host == null) return null;
    return Credentials(host: _host!, key: _privateKey);
  }

  void setCredentials(Credentials? credentials) {
    _host = credentials?.host;
    _privateKey = credentials?.key;
    notifyListeners();
  }

  String? get connectionState {
    return _connectionState;
  }

  void resetCredentials() {
    _host = null;
    _privateKey = null;
    notifyListeners();
  }

  void setConnectingFinished({bool isConnected = true}) {
    _isConnecting = false;
    _connectionState = null;
    _isConnected = isConnected;
    if (kDebugMode) {
      print('isConnected: $_isConnected');
    }

    notifyListeners();
  }

  void setConnectionState(String? connectionState) {
    _isConnecting = connectionState != null;
    if (kDebugMode) {
      print('isConnecting: $_isConnecting');
      print('connectionState: $connectionState');
    }
    _connectionState = connectionState;
    notifyListeners();
  }

  void disconnect() {
    resetCredentials();
    setConnectingFinished(isConnected: false);
  }
}
