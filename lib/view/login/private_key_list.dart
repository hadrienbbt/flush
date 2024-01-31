import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flush/controller/login_controller.dart';
import 'package:flush/model/private_key.dart';
import 'package:flush/view/login/private_key_config.dart';

class PrivateKeyList extends StatefulWidget {
  const PrivateKeyList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PrivateKeyListState();
}

class _PrivateKeyListState extends State<PrivateKeyList> {
  SavedPrivateKeys _savedKeys = [];

  @override
  void initState() {
    super.initState();
    _setSavedKeys();
  }

  void _setSavedKeys() async {
    final savedKeys = await PrivateKey.getList();
    setState(() {
      _savedKeys = savedKeys;
    });
  }

  void _removeKey(PrivateKey key) {
    key.remove();
    _setSavedKeys();
  }

  @override
  Widget build(BuildContext context) {
    void _onPressDelete(PrivateKey key) {
      final keyName = key.name;
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Private Key'),
              content: Text('Are you sure you want to delete $keyName?'),
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
                    _removeKey(key);
                  },
                ),
              ],
            );
          });
    }

    void _onSelected(int result, PrivateKey key) {
      if (result == 1) {
        _onPressDelete(key);
      }
    }

    void _onPressAddKey() async {
      final route = MaterialPageRoute(builder: (context) => const KeyConfig());
      await Navigator.push(context, route);
      _setSavedKeys();
    }

    void _onPressSelectKey(PrivateKey key) {
      LoginController loginController =
          Provider.of<LoginController>(context, listen: false);
      loginController.setPrivateKey(key);
      Navigator.pop(context);
    }

    if (_savedKeys.isEmpty) {
      return const KeyConfig();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Private keys'),
      ),
      body: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          itemCount: _savedKeys.length,
          itemBuilder: (context, index) {
            final key = _savedKeys[index];
            return Card(
              child: ListTile(
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (int value) => _onSelected(value, key),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      child: Text('Delete'),
                      value: 1,
                    )
                  ],
                ),
                title: Text(key.name),
                subtitle: Text(key.type),
                onTap: () => _onPressSelectKey(key),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: _onPressAddKey,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
