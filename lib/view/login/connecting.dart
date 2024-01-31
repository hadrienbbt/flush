import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flush/controller/login_controller.dart';

class Connecting extends StatelessWidget {
  const Connecting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FluSH'),
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Consumer<LoginController>(
              builder: (context, controller, child) {
                if (controller.connectionState == null) return Container();
                return Text(controller.connectionState!,
                    style: const TextStyle(color: Colors.black));
              },
            ),
          ]),
        ),
      ),
    );
  }
}
