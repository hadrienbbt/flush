import 'package:flush/view/app/systemd/find_service.dart';
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
    void showToast(String message) {
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

    Future<void> onSelected(
        int result, Service service, ServicesController controller) async {
      if (result == 0) {
        await controller.toggleEnabled(service.id);
        final updatedService = controller.get(service.id);
        showToast(
            'Service ${updatedService.isEnabled ? 'Enabled' : 'Disabled'}');
      } else if (result == 1) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Remove from favorite'),
                content: Text(
                    'Do you want to remove the service ${service.title.capitalize()} from your list of favorite services? (You can add it later)'),
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
                    child: const Text('REMOVE',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      Navigator.pop(context);
                      await controller.remove(service.id);
                      showToast('Remove service from favorite list');
                    },
                  ),
                ],
              );
            });
      }
    }

    Widget renderActionButtons(Service service, ServicesController controller) {
      Future<void> toggleActive() async {
        await controller.toggleActive(service.id);
        final updatedService = controller.get(service.id);
        showToast('Service ${updatedService.isActive ? 'Started' : 'Stopped'}');
      }

      Future<void> restart() async {
        await controller.restart(service.id);
        showToast('Service Restarted');
      }

      final activeIconButton = IconButton(
          onPressed: toggleActive,
          icon: Icon(service.isActive ? Icons.stop : Icons.play_arrow));
      final restartIconButton =
          IconButton(onPressed: restart, icon: const Icon(Icons.restart_alt));
      final menuButton = PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (int value) => onSelected(value, service, controller),
          itemBuilder: (context) => [
                PopupMenuItem(
                  value: 0,
                  child: Text(service.isEnabled ? 'Disable' : 'Enable'),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Text('Remove from favorite'),
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

    Widget renderEmpty(ServicesController controller) {
      final route = MaterialPageRoute(
          builder: (context) => ListenableProvider<ServicesController>.value(
                value: controller,
                child: const FindService(),
              ));
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Add service",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30.0, color: Colors.black),
            ),
            const Text(
              "Favorite services will appear here",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0, color: Colors.grey),
            ),
            const SizedBox(
              height: 20,
            ),
            FloatingActionButton(
              onPressed: () {
                Navigator.push(context, route);
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Consumer<ServicesController>(builder: (context, controller, child) {
      if (controller.loading) return _renderLoading();
      if (controller.services.isEmpty) return renderEmpty(controller);

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
                  : renderActionButtons(service, controller),
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
