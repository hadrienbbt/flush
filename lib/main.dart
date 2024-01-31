import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flush/controller/login_controller.dart';
import 'package:flush/controller/ssh_controller.dart';

void main() {
  runApp(ListenableProvider(
    create: (context) => LoginController(),
    builder: (context, child) => const FluSHApp(),
  ));
}

class FluSHApp extends StatelessWidget {
  const FluSHApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluSH',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const SSHController(),
    );
  }
}
