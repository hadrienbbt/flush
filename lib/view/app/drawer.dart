import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flush/controller/login_controller.dart';
import 'package:flush/controller/feature_flags_controller.dart';

class SSHDrawer extends StatelessWidget {
  final void Function(String) showScreen;
  final void Function() disconnect;

  const SSHDrawer(
      {Key? key, required this.showScreen, required this.disconnect})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Consumer renderFeatureFlags() {
      return Consumer<FeatureFlagsController>(
          builder: (context, controller, child) {
        return Column(
            children: controller.enabledFlags
                .map((e) => ListTile(
                      trailing: const Icon(Icons.chevron_right),
                      title: Text(e.title),
                      onTap: () {
                        Navigator.pop(context);
                        showScreen(e.screen);
                      },
                    ))
                .toList());
      });
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.teal,
            ),
            child: Header(),
          ),
          renderFeatureFlags(),
          ListTile(
            trailing: const Icon(Icons.chevron_right),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              showScreen('settings');
            },
          ),
          ListTile(
            trailing: const Icon(Icons.chevron_right),
            title: const Text('Disconnect'),
            onTap: () {
              disconnect();
            },
          ),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginController>(builder: (context, controller, child) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.webhook_rounded, color: Colors.white, size: 50),
          const Text('FluSH', style: TextStyle(color: Colors.white)),
          const SizedBox(
            height: 20,
          ),
          Text(controller.currentHostId,
              style: const TextStyle(color: Colors.white)),
        ],
      );
    });
  }
}
