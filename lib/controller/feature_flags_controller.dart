import 'package:flutter/foundation.dart';

class FeatureFlag {
  String title;
  String screen;
  bool isEnabled;
  bool isExperimental;

  FeatureFlag(
      {required this.title,
      required this.screen,
      required this.isEnabled,
      required this.isExperimental});

  void setEnabled(bool enabled) {
    isEnabled = enabled;
  }
}

class FeatureFlagsController extends ChangeNotifier {
  final List<FeatureFlag> _flags = [
    FeatureFlag(
        title: 'Systemd',
        screen: 'services',
        isExperimental: false,
        isEnabled: true),
    FeatureFlag(
        title: 'Commands',
        screen: 'commands',
        isExperimental: true,
        isEnabled: false),
    FeatureFlag(
        title: 'Tree', screen: 'tree', isExperimental: false, isEnabled: true),
    FeatureFlag(
        title: 'Shell',
        screen: 'shell',
        isExperimental: true,
        isEnabled: false),
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
