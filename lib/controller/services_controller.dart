import 'package:flutter/foundation.dart';

import 'package:flush/model/filesystem.dart';

class ServicesController extends ChangeNotifier {
  String hostId;
  Future<String> Function(String) runCommand;

  List<Service> _services = [];
  List<String> _servicesFound = [];
  bool _loading = true;

  ServicesController({required this.hostId, required this.runCommand}) {
    initSavedServices();
  }

  List<Service> get services {
    return _services;
  }

  List<String> get servicesFound {
    return _servicesFound;
  }

  bool get loading {
    return _loading;
  }

  Service get(String id) {
    return _services.firstWhere((element) => element.id == id);
  }

  void initSavedServices() async {
    _loading = true;
    _services.clear();
    _services = await Service.getList(hostId, runCommand);
    _loading = false;
    notifyListeners();
  }

  Future<bool> saveService(String name) async {
    final service = await Service.create(name, runCommand);
    if (service != null) {
      _services.add(service);
      service.save(hostId);
      _servicesFound.remove(name);
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<void> updateStatus(String id) async {
    final service = get(id);
    service.loading = true;
    notifyListeners();
    await service.updateStatus();
    service.loading = false;
    notifyListeners();
  }

  Future<void> restart(String id) async {
    final service = get(id);
    service.loading = true;
    notifyListeners();
    await service.restart();
    service.loading = false;
    notifyListeners();
  }

  Future<void> toggleActive(String id) async {
    final service = get(id);
    service.loading = true;
    notifyListeners();
    await service.toggleActive();
    service.loading = false;
    notifyListeners();
  }

  Future<void> toggleEnabled(String id) async {
    final service = get(id);
    service.loading = true;
    notifyListeners();
    await service.toggleEnabled();
    service.loading = false;
    notifyListeners();
  }

  Future<void> remove(String id) async {
    final service = get(id);
    service.loading = true;
    notifyListeners();
    await service.remove(hostId);
    _services.removeWhere((element) => element.id == id);
    service.loading = false;
    notifyListeners();
  }

  void findServices() async {
    _loading = true;
    _servicesFound.clear();
    final result =
        await runCommand('systemctl list-unit-files | grep .service');
    _servicesFound = result
        .split('\n')
        .map((element) {
          RegExp regExp = RegExp(r'(.*)(?=.service)');
          return regExp.stringMatch(element) ?? '';
        })
        .where((element) =>
            element.isNotEmpty && !_services.any((e) => e.title == element))
        .toList();
    _loading = false;
    notifyListeners();
  }
}
