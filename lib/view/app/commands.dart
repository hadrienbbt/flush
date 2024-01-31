import 'package:flutter/material.dart';

class Commands extends StatefulWidget {
  final Future<String> Function(String) runCommand;
  final String path;

  const Commands({Key? key, required this.runCommand, this.path = ''})
      : super(key: key);

  @override
  State<Commands> createState() => _CommandsState();
}

class _CommandsState extends State<Commands> {
  String _output = '';
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void onSubmitted(String text) async {
    setState(() {
      _output = '';
    });
    _controller.clear();
    String output = await widget.runCommand(text);
    setState(() {
      _output = output;
    });
  }

  Widget _renderTextField() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
            controller: _controller,
            onSubmitted: onSubmitted,
            autocorrect: false,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => onSubmitted(_controller.text),
              ),
            )));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _renderTextField(),
          const SizedBox(height: 10),
          Text(_output)
        ],
      ),
    );
  }
}
