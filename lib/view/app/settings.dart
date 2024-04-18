import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flush/controller/feature_flags_controller.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Consumer renderFeatureFlags() {
      return Consumer<FeatureFlagsController>(
          builder: (context, controller, child) {
        return Column(
            children: controller.featureFlags
                .map((e) => Row(
                      children: [
                        Text(e.isExperimental
                            ? "[Experimental] ${e.title}"
                            : e.title),
                        const Spacer(),
                        Switch(
                            value: e.isEnabled,
                            onChanged: (enabled) =>
                                controller.setEnabled(e, enabled))
                      ],
                    ))
                .toList());
      });
    }

    return Padding(
        padding: const EdgeInsets.all(15), child: renderFeatureFlags());
  }
}
