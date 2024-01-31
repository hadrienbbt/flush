import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flush/controller/services_controller.dart';
import 'package:flush/utils/string_extension.dart';

class ServiceDetail extends StatelessWidget {
  final String serviceId;

  const ServiceDetail({Key? key, required this.serviceId}) : super(key: key);

  TextButton _renderStatusBtn(ServicesController controller) {
    return TextButton(
        style: TextButton.styleFrom(backgroundColor: Colors.teal),
        child: const Text('Status', style: TextStyle(color: Colors.white)),
        onPressed: () => controller.updateStatus(serviceId));
  }

  TextButton _renderRestartButton(ServicesController controller) {
    return TextButton(
        style: TextButton.styleFrom(backgroundColor: Colors.teal),
        child: const Text('Restart', style: TextStyle(color: Colors.white)),
        onPressed: () => controller.restart(serviceId));
  }

  TextButton _renderActiveButton(ServicesController controller) {
    return TextButton(
        style: TextButton.styleFrom(backgroundColor: Colors.teal),
        child: Text(controller.get(serviceId).isActive ? 'Stop' : 'Start',
            style: const TextStyle(color: Colors.white)),
        onPressed: () => controller.toggleActive(serviceId));
  }

  TextButton _renderEnableButton(ServicesController controller) {
    return TextButton(
        style: TextButton.styleFrom(backgroundColor: Colors.teal),
        child: Text(controller.get(serviceId).isEnabled ? 'Disable' : 'Enable',
            style: const TextStyle(color: Colors.white)),
        onPressed: () => controller.toggleEnabled(serviceId));
  }

  Widget _renderButtons(ServicesController controller) {
    if (!controller.get(serviceId).isEnabled) {
      return _renderEnableButton(controller);
    }
    return Row(
      children: [
        _renderStatusBtn(controller),
        const Spacer(),
        _renderActiveButton(controller),
        const Spacer(),
        _renderRestartButton(controller),
        const Spacer(),
        _renderEnableButton(controller),
      ],
    );
  }

  Widget _renderLoading() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServicesController>(
      builder: (context, controller, child) {
        final service = controller.get(serviceId);
        return Scaffold(
          appBar: AppBar(
            title: Text(service.name.capitalize()),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Systemd'),
                    _renderButtons(controller),
                    const Divider(),
                    service.loading ? _renderLoading() : Text(service.status)
                  ]),
            ),
          ),
        );
      },
    );
  }
}
