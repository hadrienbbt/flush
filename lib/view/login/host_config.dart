import 'package:flush/model/host.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flush/controller/ssh_controller.dart' show ErrorHandler;
import 'package:flush/controller/login_controller.dart';
import 'package:flush/model/credentials.dart';
import 'package:flush/view/login/private_key_list.dart';

class HostConfig extends StatefulWidget {
  final Credentials? credentials;
  final Future<void> Function({ErrorHandler? onError}) connect;

  const HostConfig({Key? key, this.credentials, required this.connect})
      : super(key: key);

  @override
  State<HostConfig> createState() => _HostConfigState();
}

class _HostConfigState extends State<HostConfig> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.credentials;
    if (c != null) {
      _hostController.text = c.host.name;
      _usernameController.text = c.host.user;
      _portController.text = c.host.port.toString();
    } else {
      _portController.text = '22';
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void showToast(BuildContext context, String errorMessage) {
      if (kDebugMode) {
        print(errorMessage);
      }
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          action: SnackBarAction(
              label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
        ),
      );
    }

    void onPressConnect() async {
      final String hostname = _hostController.text.trim();
      if (hostname.isEmpty) {
        return showToast(context, 'No host provided');
      }

      final int? port = int.tryParse(_portController.text.trim());
      if (port == null) {
        return showToast(context, 'No port provided');
      }

      final String username = _usernameController.text.trim();
      if (username.isEmpty) {
        return showToast(context, 'No username provided');
      }

      LoginController loginController =
          Provider.of<LoginController>(context, listen: false);

      final host = Host(
          name: _hostController.text.trim(),
          port: int.tryParse(_portController.text.trim()),
          user: _usernameController.text.trim());
      loginController.setHost(host);

      widget.connect(onError: (error) {
        showToast(context, error ?? 'Unable to login');
      });
    }

    List<Widget> renderHost() {
      return [
        TextField(
            controller: _hostController,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'IP address or Domain name',
              suffixIcon: Icon(Icons.home),
            )),
        const SizedBox(height: 10),
        TextField(
            controller: _usernameController,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Username',
              suffixIcon: Icon(Icons.perm_identity),
            )),
        const SizedBox(height: 10),
        TextField(
            controller: _portController,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Port',
              suffixIcon: Icon(Icons.numbers),
            )),
        const SizedBox(height: 10),
      ];
    }

    Widget renderPrivateKey() {
      return Consumer<LoginController>(
        builder: (context, controller, child) {
          return ListTile(
            leading: controller.privateKey != null
                ? IconButton(
                    onPressed: () => controller.setPrivateKey(null),
                    icon: const Icon(Icons.clear))
                : null,
            trailing: const Icon(Icons.key),
            title: Text(controller.privateKey?.name ?? 'Private Key'),
            subtitle: controller.privateKey != null
                ? Text(controller.privateKey!.type)
                : null,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivateKeyList())),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.credentials?.host.id ?? 'New SSH Config'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(children: [
              ...renderHost(),
              renderPrivateKey(),
              const SizedBox(height: 40),
              TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: onPressConnect,
                  child: const Text('CONNECT',
                      style: TextStyle(color: Colors.white))),
              const SizedBox(height: 10),
            ]),
          ),
        ),
      ),
    );
  }
}
