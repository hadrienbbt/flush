import 'package:flutter/foundation.dart';

class FeatureFlag {
  String title;
  String screen;
  bool isEnabled;

  FeatureFlag(
      {required this.title, required this.screen, required this.isEnabled});

  void setEnabled(bool enabled) {
    isEnabled = enabled;
  }
}

class FeatureFlagsController extends ChangeNotifier {
  final List<FeatureFlag> _flags = [
    FeatureFlag(title: 'Systemd', screen: 'services', isEnabled: true),
    FeatureFlag(title: 'Commands', screen: 'commands', isEnabled: false),
    FeatureFlag(title: 'Tree', screen: 'tree', isEnabled: true),
    FeatureFlag(title: 'Shell', screen: 'shell', isEnabled: false),
  ];

  List<FeatureFlag> get featureFlags {
    return _flags;
  }

  List<FeatureFlag> get enabledFlags {
    return _flags.where((element) => element.isEnabled).toList();
  }

  void setEnabled(FeatureFlag flag, bool enabled) {
    flag.setEnabled(enabled);
    notifyListeners();
  }
}
