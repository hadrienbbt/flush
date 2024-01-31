import 'package:flush/controller/services_controller.dart';
import 'package:flutter/material.dart';

import 'package:dartssh2/dartssh2.dart';
import 'package:provider/provider.dart';

import 'package:flush/view/app/systemd/service_list.dart';
import 'package:flush/view/app/systemd/find_service.dart';
import 'package:flush/view/app/drawer.dart';
import 'package:flush/view/app/shell.dart';
import 'package:flush/view/app/tree.dart';
import 'package:flush/view/app/commands.dart';
import 'package:flush/view/app/settings.dart';

class App extends StatefulWidget {
  final SSHClient client;
  final Future<String> Function(String) runCommand;
  final void Function() disconnect;

  const App(
      {Key? key,
      required this.client,
      required this.runCommand,
      required this.disconnect})
      : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String _route = 'tree';
  SftpClient? _sftp;

  @override
  void initState() {
    super.initState();
    _setSFTPClient();
  }

  void _setSFTPClient() async {
    final sftp = await widget.client.sftp();
    setState(() {
      _sftp = sftp;
    });
  }

  void _showScreen(String route) {
    setState(() {
      _route = route;
    });
  }

  String _getTitle() {
    if (_route == 'commands') {
      return 'Commands';
    }
    if (_route == 'tree' && _sftp != null) {
      return 'Tree';
    }
    if (_route == 'shell') {
      return 'Shell';
    }
    if (_route == 'services') {
      return 'Systemd';
    }
    if (_route == 'settings') {
      return 'Settings';
    }
    return '';
  }

  Widget _renderApp() {
    if (_route == 'commands') {
      return Commands(runCommand: widget.runCommand);
    }
    if (_route == 'tree' && _sftp != null) {
      return Tree(
          client: widget.client, sftp: _sftp!, runCommand: widget.runCommand);
    }
    if (_route == 'shell') {
      return Shell(client: widget.client, runCommand: widget.runCommand);
    }
    if (_route == 'services') {
      return const ServiceList();
    }
    if (_route == 'settings') {
      return const Settings();
    }
    return Container(
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesController =
        Provider.of<ServicesController>(context, listen: false);

    Widget? _renderFloatingButton() {
      if (_route == 'services') {
        final route = MaterialPageRoute(
            builder: (context) => ListenableProvider<ServicesController>.value(
                  value: servicesController,
                  child: const FindService(),
                ));
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(context, route);
          },
          child: const Icon(Icons.add),
        );
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(_getTitle())),
      body: _renderApp(),
      drawer: SSHDrawer(showScreen: _showScreen, disconnect: widget.disconnect),
      floatingActionButton: _renderFloatingButton(),
    );
  }
}
