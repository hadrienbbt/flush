import 'package:flush/controller/login_controller.dart';
import 'package:flutter/material.dart';

import 'package:flush/controller/ssh_controller.dart' show ErrorHandler;
import 'package:flush/model/credentials.dart';
import 'package:flush/view/login/host_config.dart';
import 'package:provider/provider.dart';

class HostList extends StatefulWidget {
  final Future<void> Function({ErrorHandler? onError}) connect;

  const HostList({Key? key, required this.connect}) : super(key: key);

  @override
  State<HostList> createState() => _HostListState();
}

class _HostListState extends State<HostList> {
  SavedCredentials _savedCredentials = [];

  @override
  void initState() {
    super.initState();
    _setSavedCredentials();
  }

  void _setSavedCredentials() async {
    final savedCredentials = await Credentials.getList();
    setState(() {
      _savedCredentials = savedCredentials;
    });
  }

  void _removeCredentials(Credentials credential) {
    credential.remove();
    _setSavedCredentials();
  }

  @override
  Widget build(BuildContext context) {
    if (_savedCredentials.isEmpty) {
      return HostConfig(connect: widget.connect);
    }

    void onPressAddConfig(LoginController controller) {
      controller.setCredentials(null);
      final route = MaterialPageRoute(
          builder: (context) => HostConfig(connect: widget.connect));
      Navigator.push(context, route);
    }

    void onPress(Credentials credentials, LoginController controller) {
      controller.setCredentials(credentials);
      Navigator.push(context, MaterialPageRoute(builder: (conext) {
        return HostConfig(credentials: credentials, connect: widget.connect);
      }));
    }

    void onPressDelete(Credentials credentials) {
      final credentialsName = credentials.host.id;
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Credentials'),
              content:
                  Text('Are you sure you want to delete $credentialsName?'),
              actions: [
                TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.white),
                    child: const Text('CANCEL',
                        style: TextStyle(color: Colors.teal)),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('DELETE',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context);
                    _removeCredentials(credentials);
                  },
                ),
              ],
            );
          });
    }

    void onSelected(int result, Credentials credential) {
      if (result == 1) {
        onPressDelete(credential);
      }
    }

    return Consumer<LoginController>(builder: (context, controller, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved SSH Configs'),
        ),
        body: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: _savedCredentials.length,
            itemBuilder: (context, index) {
              final credential = _savedCredentials[index];
              return Card(
                child: ListTile(
                  trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (int value) => onSelected(value, credential),
                      itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 1,
                              child: Text('Delete'),
                            )
                          ]),
                  title: Text(credential.host.name),
                  subtitle: Text(
                      'User: ${credential.host.user}\nPrivate key: ${credential.key?.name ?? 'Empty'}'),
                  isThreeLine: true,
                  onTap: () => onPress(credential, controller),
                ),
              );
            }),
        floatingActionButton: FloatingActionButton(
          onPressed: () => onPressAddConfig(controller),
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    });
  }
}
