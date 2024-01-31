import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

class Shell extends StatefulWidget {
  final SSHClient client;
  final Future<String> Function(String) runCommand;

  const Shell({Key? key, required this.client, required this.runCommand})
      : super(key: key);

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  List<String> _stdout = [];
  late SSHSession _shell;
  StreamSubscription<Uint8List>? listener;

  @override
  void initState() {
    super.initState();
    _startProcess();
    // _startShell();
  }

  void _startProcess() async {
    final session = await widget.client.execute('cat > file.txt');
    await session.stdin.addStream(File('local_file.txt').openRead().cast());
    await session.stdin
        .close(); // Close the sink to send EOF to the remote process.

    await session
        .done; // Wait for session to exit to ensure all data is flushed to the remote process.
    print(session.exitCode);
  }

  _restartShell() {
    _shell.close();
    _startShell();
  }

  _clear() {
    setState(() {
      _stdout = [];
    });
  }

  _onPress() {
    List<int> list = 'ls -al'.codeUnits;
    Uint8List bytes = Uint8List.fromList(list);
    _shell.write(bytes);
  }

  _onData(Uint8List event) {
    setState(() {
      _stdout = [..._stdout, String.fromCharCodes(event)];
    });
  }

  void _startShell() async {
    final shell = await widget.client.shell();
    shell.resizeTerminal(300, 300);
    stdout.addStream(shell.stdout); // listening for stdout
    stderr.addStream(shell.stderr); // listening for stderr
    stdin.cast<Uint8List>().listen(shell.write); // writing to stdin
    // if (listener != null) {
    //   listener!.cancel();
    //   listener = null;
    // }
    // listener = shell.stdout.listen(_onData);

    setState(() {
      _shell = shell;
    });
    await shell.done;
    print('Session terminated');
    // listener!.cancel();
    // listener = null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: _onPress,
                  child: const Text('ls -al',
                      style: TextStyle(color: Colors.white))),
              const Spacer(),
              TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: _restartShell,
                  child: const Text('Restart',
                      style: TextStyle(color: Colors.white))),
              const Spacer(),
              TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: _clear,
                  child: const Text('Clear',
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
        Text(stdout.toString()),
        Column(children: _stdout.map((e) => Text(e)).toList()),
      ]),
    );
  }
}
