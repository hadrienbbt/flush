import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:dartssh2/dartssh2.dart';

class Tree extends StatefulWidget {
  final SSHClient client;
  final SftpClient sftp;
  final Future<String> Function(String) runCommand;
  final String path;

  const Tree(
      {Key? key,
      required this.client,
      required this.sftp,
      required this.runCommand,
      this.path = ''})
      : super(key: key);

  @override
  State<Tree> createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  bool _hiddenFiles = true;
  bool _loading = true;
  List<SftpName> _sftpNames = [];

  List<String> get _items {
    List<String> items = _sftpNames
        .where((e) {
          if (e.filename == '.' || e.filename == '..') return false;
          if (_hiddenFiles) return true;
          return !e.filename.startsWith('.');
        })
        .map((e) => e.filename)
        .toList();
    items.sort();
    return items;
  }

  List<SftpName> get _files {
    return _sftpNames.where((element) => element.attr.isFile).toList();
  }

  List<SftpName> get _dirs {
    return _sftpNames.where((element) => element.attr.isDirectory).toList();
  }

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getItemsInTree();
  }

  void _showErrorAlert(SftpError e) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(e.message),
            actions: [
              TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  void _getItemsInTree() async {
    try {
      final List<SftpName> sftpNames =
          await widget.sftp.listdir(widget.path.isNotEmpty ? widget.path : '/');
      setState(() {
        _loading = false;
        _sftpNames = sftpNames;
      });
    } on SftpError catch (e) {
      Navigator.pop(context);
      _showErrorAlert(e);
    } catch (e) {
      print('Unknown error: ' + e.toString());
    }
  }

  void _showToast(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  void _toggleHiddenFiles() {
    setState(() {
      _hiddenFiles = !_hiddenFiles;
    });
    _getItemsInTree();
  }

  void _newFolder() async {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('New Folder'),
              content: TextField(
                controller: _controller,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
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
                  child: const Text('CREATE',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await widget.sftp
                          .mkdir(widget.path + '/' + _controller.text);
                    } on SftpError catch (e) {
                      _showErrorAlert(e);
                    }
                    _getItemsInTree();
                  },
                ),
              ],
            ));
  }

  void _onSelected(int value) {
    if (value == 0) {
      _toggleHiddenFiles();
    } else if (value == 1) {
      _newFolder();
    }
  }

  void _onLongPress(int index) async {
    final item = _items[index];
    final isDir = _dirs.map((e) => e.filename).toList().contains(item);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Delete ' + (isDir ? 'Folder' : 'File')),
            content: Text('Are you sure you want to delete $item?'),
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
                child:
                    const Text('DELETE', style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    if (isDir) {
                      await widget.sftp.rmdir(widget.path + '/' + item);
                    } else {
                      await widget.sftp.remove(widget.path + '/' + item);
                    }
                    _getItemsInTree();
                  } on SftpError catch (e) {
                    print(e);
                    _showErrorAlert(e);
                  }
                },
              ),
            ],
          );
        });
  }

  void _showRunScriptDialog(String filename, String path) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Run script'),
            content: Text('Do you want to run the scipt $filename?'),
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
                child: const Text('RUN', style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  Navigator.pop(context);
                  widget.runCommand('sudo bash ' + path);
                  _showToast(context, 'Script running');
                },
              ),
            ],
          );
        });
  }

  void _onTap(int index) async {
    final newPath = widget.path + '/' + _items[index];
    if (_dirs.map((e) => e.filename).toList().contains(_items[index])) {
      Navigator.push(context, MaterialPageRoute(builder: (conext) {
        return Tree(
          client: widget.client,
          sftp: widget.sftp,
          runCommand: widget.runCommand,
          path: newPath,
        );
      }));
    } else {
      final extension = p.extension(_items[index]);
      if (extension == '.sh') {
        _showRunScriptDialog(_items[index], newPath);
      } else {
        final content = await widget.runCommand('cat ' + newPath);
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.path),
            ),
            body: SingleChildScrollView(
              child: Text(content),
            ),
          );
        }));
      }
    }
  }

  Widget renderItemList() {
    if (_loading) {
      return Container(
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
    return ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) => ListTile(
              title: Text(_items[index]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _onTap(index),
              onLongPress: () => _onLongPress(index),
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.path.isEmpty) return renderItemList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path),
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: _onSelected,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<int>(
                  value: 0,
                  child:
                      Text((_hiddenFiles ? 'Hide' : 'Show') + ' hidden files'),
                ),
                const PopupMenuItem<int>(
                  value: 1,
                  child: Text('New Folder'),
                )
              ];
            },
          ),
        ],
      ),
      body: renderItemList(),
    );
  }
}
