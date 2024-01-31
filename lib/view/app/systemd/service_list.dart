import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flush/controller/services_controller.dart';
import 'package:flush/model/filesystem.dart';
import 'package:flush/view/app/systemd/service_detail.dart';
import 'package:flush/utils/string_extension.dart';

class ServiceList extends StatelessWidget {
  const ServiceList({Key? key}) : super(key: key);

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
    void _showToast(String message) {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
              label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
        ),
      );
    }

    Future<void> _onSelected(
        int result, Service service, ServicesController controller) async {
      if (result == 0) {
        await controller.toggleEnabled(service.id);
        final updatedService = controller.get(service.id);
        _showToast(
            'Service ${updatedService.isEnabled ? 'Enabled' : 'Disabled'}');
      } else if (result == 1) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Delete Service'),
                content: Text(
                    'Do you want to delete the service ${service.title.capitalize()} ?'),
                actions: [
                  TextButton(
                      style:
                          TextButton.styleFrom(backgroundColor: Colors.white),
                      child: const Text('CANCEL',
                          style: TextStyle(color: Colors.teal)),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                  TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('DELETE',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      Navigator.pop(context);
                      await controller.remove(service.id);
                      _showToast('Service Removed');
                    },
                  ),
                ],
              );
            });
      }
    }

    Widget _renderActionButtons(
        Service service, ServicesController controller) {
      Future<void> _toggleActive() async {
        await controller.toggleActive(service.id);
        final updatedService = controller.get(service.id);
        _showToast(
            'Service ${updatedService.isActive ? 'Started' : 'Stopped'}');
      }

      Future<void> _restart() async {
        await controller.restart(service.id);
        _showToast('Service Restarted');
      }

      final activeIconButton = IconButton(
          onPressed: _toggleActive,
          icon: Icon(service.isActive ? Icons.stop : Icons.play_arrow));
      final restartIconButton =
          IconButton(onPressed: _restart, icon: const Icon(Icons.restart_alt));
      final menuButton = PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (int value) => _onSelected(value, service, controller),
          itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(service.isEnabled ? 'Disable' : 'Enable'),
                  value: 0,
                ),
                const PopupMenuItem(
                  child: Text('Delete'),
                  value: 1,
                )
              ]);
      List<Widget> buttons = [menuButton];
      if (service.isEnabled) {
        buttons.insert(0, activeIconButton);
      }
      if (service.isActive) {
        buttons.insert(0, restartIconButton);
      }
      return Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: buttons,
      );
    }

    return Consumer<ServicesController>(builder: (context, controller, child) {
      if (controller.loading) return _renderLoading();
      if (controller.services.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Text('No systemd service'),
        );
      }
      return ListView.builder(
          itemCount: controller.services.length,
          itemBuilder: (context, index) {
            final service = controller.services[index];
            final activeStatus = service.isActive ? 'Active' : 'Inactive';
            final status =
                service.isEnabled ? 'Enabled - $activeStatus' : 'Disabled';
            return ListTile(
              title: Text(service.title.capitalize()),
              subtitle: Text(service.loading ? '' : status),
              trailing: service.loading
                  ? const SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(),
                    )
                  : _renderActionButtons(service, controller),
              onTap: () {
                final route = MaterialPageRoute(
                    builder: (context) =>
                        ListenableProvider<ServicesController>.value(
                          value: controller,
                          child: ServiceDetail(
                            serviceId: service.id,
                          ),
                        ));
                Navigator.push(context, route);
              },
            );
          });
    });
  }
}
