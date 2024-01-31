import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:flush/controller/services_controller.dart';
import 'package:flush/utils/string_extension.dart';

class FindService extends StatefulWidget {
  const FindService({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FindServiceState();
}

class _FindServiceState extends State<FindService> {
  List<String> services = [];
  String searchString = '';
  @override
  void initState() {
    super.initState();
    final controller = Provider.of<ServicesController>(context, listen: false);
    controller.findServices();
  }

  Widget _renderLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        CircularProgressIndicator(),
        SizedBox(
          height: 20,
        ),
        Text('Searching for services')
      ],
    );
  }

  Widget _renderEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Text('No service found'),
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

    void _onServiceTaped(String service) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Add Service'),
              content: Text(
                  'Do you want to add $service to your list of services ?'),
              actions: [
                TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.white),
                    child: const Text('CANCEL',
                        style: TextStyle(color: Colors.teal)),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.teal),
                  child:
                      const Text('ADD', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await Provider.of<ServicesController>(
                            context,
                            listen: false)
                        .saveService(service);
                    if (success) {
                      _showToast('Service Added');
                    } else {
                      _showToast('Error adding service');
                    }
                  },
                ),
              ],
            );
          });
    }

    Widget _renderServicesFound() {
      return Consumer<ServicesController>(
          builder: (context, controller, child) {
        if (controller.loading) return _renderLoading();
        if (controller.servicesFound.isEmpty) return _renderEmpty();
        return ListView.separated(
          itemCount: controller.servicesFound.length,
          separatorBuilder: (context, index) {
            final service = controller.servicesFound[index];
            if (searchString.isEmpty ||
                service.toLowerCase().contains(searchString)) {
              return const Divider();
            }
            return Container();
          },
          itemBuilder: (context, index) {
            final service = controller.servicesFound[index];
            if (searchString.isEmpty ||
                service.toLowerCase().contains(searchString)) {
              return ListTile(
                title: Text(service.capitalize()),
                onTap: () => _onServiceTaped(service),
              );
            }
            return Container();
          },
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Service')),
      body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchString = value.toLowerCase();
                  });
                },
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Search service',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _renderServicesFound())
          ]),
    );
  }
}
