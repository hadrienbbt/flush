import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:dartssh2/src/ssh_userauth.dart' show SSHUserInfoRequest;

class UserInfoAlert extends StatelessWidget {
  final void Function(List<String>? userInfo) sendUserInfo;
  final SSHUserInfoRequest request;

  const UserInfoAlert(
      {Key? key, required this.sendUserInfo, required this.request})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<TextEditingController> controllers =
        request.prompts.map((e) => TextEditingController()).toList();

    Widget renderTextFields() {
      return Wrap(
          children: request.prompts
              .asMap()
              .map((i, prompt) => MapEntry(
                  i,
                  Wrap(
                    children: [
                      TextField(
                        controller: controllers[i],
                        obscureText: !prompt.echo,
                        decoration:
                            InputDecoration(hintText: prompt.promptText),
                      ),
                      const SizedBox(
                        height: 10,
                      )
                    ],
                  )))
              .values
              .toList());
    }

    final title = request.name.isNotEmpty ? request.name : 'User Info Request';
    final instructions =
        request.instruction.isNotEmpty ? request.instruction : '';

    return AlertDialog(
      title: Text(title),
      content: Wrap(children: [Text(instructions), renderTextFields()]),
      actions: [
        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('CANCEL', style: TextStyle(color: Colors.teal)),
            onPressed: () {
              sendUserInfo(null);
            }),
        TextButton(
          style: TextButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
          onPressed: () {
            sendUserInfo(controllers.map((e) => e.text).toList());
          },
        ),
      ],
    );
  }
}
