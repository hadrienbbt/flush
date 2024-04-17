import 'dart:async';
import 'dart:io';
import 'dart:convert' show utf8;

import 'package:flush/main.dart';
import 'package:flush/model/flush_ssh_socket.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dartssh2/dartssh2.dart';
// ignore: implementation_imports
import 'package:dartssh2/src/ssh_userauth.dart'
    show SSHUserInfoRequest, SSHUserInfoPrompt;
import 'package:tuple/tuple.dart';
import 'package:provider/provider.dart';

import 'package:flush/controller/feature_flags_controller.dart';
import 'package:flush/controller/services_controller.dart';
import 'package:flush/controller/login_controller.dart';
import 'package:flush/model/private_key.dart';

import 'package:flush/view/login/host_list.dart';
import 'package:flush/view/app/main.dart';
import 'package:flush/view/login/user_info_request.dart';

typedef UserInfo = List<String>;
typedef KeyPairs = List<SSHKeyPair>;
typedef ParamResolver = Tuple2<KeyPairs?, String?>;
typedef ErrorHandler = Function(String?);

List<SSHKeyPair> decryptKeyPairs(List<String> args) {
  return SSHKeyPair.fromPem(args[0], args[1]);
}

class SSHController extends StatefulWidget {
  const SSHController({Key? key}) : super(key: key);

  @override
  State<SSHController> createState() => _SSHControllerState();
}

class _SSHControllerState extends State<SSHController> {
  SSHClient? _client;
  SSHUserInfoRequest? _userInfoRequest;
  UserInfo? _userInfo;

  /// Returns optional errorMessage
  Future<ParamResolver> getKeyPairs(PrivateKey key) async {
    try {
      if (key.isEncrypted) {
        final keypairs =
            await compute(decryptKeyPairs, [key.pemText, key.passphrase!]);
        return ParamResolver(keypairs, null);
      } else {
        final keypairs = await compute(decryptKeyPairs, [key.pemText]);
        return ParamResolver(keypairs, null);
      }
    } on PlatformException catch (e) {
      return ParamResolver(
          null, 'Error: ${e.code}\nError Message: ${e.message}');
    } on MissingPluginException catch (e) {
      return ParamResolver(null, 'MissingPluginException Error: ${e.message}');
    } catch (e) {
      return ParamResolver(null, '$e');
    }
  }

  void _setUserInfo(UserInfo? userInfo) {
    setState(() {
      _userInfo = userInfo;
      _userInfoRequest = null;
    });
  }

  void _setClient(SSHClient client, LoginController loginController,
      ErrorHandler? onError) {
    client.done.then(
      (_) => loginController.setConnectingFinished(isConnected: false),
      onError: (e) {
        loginController.setConnectingFinished(isConnected: false);
        if (onError != null) {
          if (e is SSHAuthFailError) {
            onError('Auth failed: ${e.message}');
          } else {
            onError(e.toString());
          }
        }
      },
    );
    setState(() {
      _client = client;
    });
  }

  Future<String> _runCommand(String command) async {
    try {
      final res = await _client!.run(command);
      return utf8.decode(res).trim();
    } on SSHChannelOpenError {
      print('rerunning command in 1s');
      return Future.delayed(const Duration(seconds: 1), () {
        return _runCommand(command);
      });
    } catch (e) {
      return e.toString();
    }
  }

  void _disconnect(LoginController loginController) async {
    if (_client != null && !_client!.isClosed) {
      _client!.close();
    }
    if (stdout.hasTerminal) stdout.close();
    if (stderr.hasTerminal) stderr.close();
    final app = ListenableProvider<LoginController>.value(
      value: loginController,
      child: const FluSHApp(),
    );
    runApp(app);
  }

  void _onAuthenticated(LoginController loginController) async {
    if (loginController.credentials != null) {
      loginController.credentials!.save();
    }

    final app = MultiProvider(
      providers: [
        ListenableProvider<LoginController>.value(value: loginController),
        ChangeNotifierProvider(
          create: (context) => FeatureFlagsController(),
        ),
        ChangeNotifierProvider(
          create: (context) => ServicesController(
              hostId: loginController.currentHostId, runCommand: _runCommand),
        ),
      ],
      builder: (context, child) => MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        home: App(
          client: _client!,
          runCommand: _runCommand,
          disconnect: () => _disconnect(loginController),
        ),
      ),
    );
    loginController.setConnectingFinished();

    runApp(app);
  }

  @override
  Widget build(BuildContext context) {
    FutureOr<void> displayTextInputDialog() async {
      if (_userInfoRequest == null) return;
      return showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return UserInfoAlert(
                request: _userInfoRequest!,
                sendUserInfo: (userInfo) {
                  _setUserInfo(userInfo);
                  Navigator.of(context).pop();
                });
          });
    }

    FutureOr<UserInfo?> onUserInfoRequest(SSHUserInfoRequest request) async {
      if (request.prompts.isEmpty) {
        return [];
      }
      setState(() {
        _userInfoRequest = request;
      });
      await displayTextInputDialog();
      return _userInfo;
    }

    FutureOr<String?> onPasswordRequest() async {
      final prompt = SSHUserInfoPrompt('Password', false);
      final request = SSHUserInfoRequest('Password Request', '', [prompt]);
      final userInfo = await onUserInfoRequest(request);
      return userInfo?.first;
    }

    Future<void> connect({ErrorHandler? onError}) async {
      LoginController loginController =
          Provider.of<LoginController>(context, listen: false);

      final credentials = loginController.credentials;
      if (credentials == null) {
        if (onError != null) onError(null);
        return;
      }

      List<SSHKeyPair>? keypairs;
      if (credentials.key != null) {
        loginController.setConnectionState('Decoding private key...');

        final resolver = await getKeyPairs(credentials.key!);
        keypairs = resolver.item1;
        final errorMessage = resolver.item2;

        if (errorMessage != null) {
          loginController.setConnectingFinished(isConnected: false);
          if (onError != null) {
            onError(errorMessage);
          }
          return;
        }
      }

      loginController.setConnectionState('Connecting...');
      try {
        final client = SSHClient(
            await FlushSSHSocket.connect(
                credentials.host.name, credentials.host.port!),
            username: credentials.host.user,
            identities: keypairs,
            onAuthenticated: () => _onAuthenticated(loginController),
            onUserInfoRequest: onUserInfoRequest,
            onPasswordRequest: onPasswordRequest,
            onUserauthBanner: (String banner) =>
                loginController.setConnectionState(banner));
        _setClient(client, loginController, onError);
      } catch (e) {
        loginController.setConnectingFinished(isConnected: false);
        if (onError != null) {
          onError(e.toString());
        }
      }
    }

    return HostList(connect: connect);
  }
}
