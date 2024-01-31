import 'package:shared_preferences/shared_preferences.dart';

import 'package:flush/model/encodable.dart' show Ref;

class File {
  final String name;
  final String path;
  late final String fullpath;
  // late final String extension;
  final Future<String> Function(String) runCommand;

  File({required this.name, required this.path, required this.runCommand}) {
    fullpath = path + name;
  }

  Future<void> rm() async {
    await runCommand('sudo rm "$fullpath"');
  }

  Future<void> chmod(String permission) async {
    await runCommand('sudo chmod "$permission" "$fullpath"');
  }

  Future<List<File>> _getFiles(String pathname, bool hiddenFiles,
      Future<String> Function(String) runCommand) async {
    String cmd = 'ls -';
    if (hiddenFiles) {
      cmd = cmd + 'a';
    }
    final path = pathname.isEmpty ? '/' : pathname;
    cmd = cmd + 'p ' + path + '| grep -v /';
    final res = await runCommand(cmd);
    if (res.isEmpty) return [];
    return res
        .split('\n')
        .map((e) => File(name: e, path: path, runCommand: runCommand))
        .toList();
  }

  Future<List<Directory>> _getDirectories(String pathname, bool hiddenFiles,
      Future<String> Function(String) runCommand) async {
    String cmd = 'ls -';
    if (hiddenFiles) {
      cmd = cmd + 'a';
    }
    final path = pathname.isEmpty ? '/' : pathname;
    cmd = cmd + 'p ' + path + '| grep /';
    final res = await runCommand(cmd);
    if (res.isEmpty) return [];
    return res
        .split('\n')
        .map((e) => e.substring(0, e.length - 1))
        .where((e) => e != '.' && e != '..' && e != '~')
        .map((e) =>
            Directory(name: e, path: path, items: [], runCommand: runCommand))
        .toList();
  }
}

class Directory extends File {
  final List<File> items;

  Directory(
      {required name, required path, required this.items, required runCommand})
      : super(name: name, path: path, runCommand: runCommand);

  Future<void> cd() async {
    await runCommand('sudo cd "$fullpath"');
  }

  @override
  Future<void> rm() async {
    await runCommand('sudo rm -r "$fullpath"');
  }
}

// Systemd service
class Service extends File {
  late String id;
  late String title;
  late bool isActive;
  late bool isEnabled;
  late String status;
  bool loading = false;

  Service._({required name, required path, required runCommand})
      : super(name: name, path: path, runCommand: runCommand);

  static Future<Service?> create(
      String name, Future<String> Function(String) runCommand) async {
    RegExp exp = RegExp(r'(?<=FragmentPath=)(.*)(?=.service)');
    final fragmentPath =
        await runCommand('systemctl show -p FragmentPath $name');
    final path = exp.stringMatch(fragmentPath).toString();
    if (path.isEmpty) return null;
    var service = Service._(name: name, path: path, runCommand: runCommand);
    service.id = name;
    service.title = name;
    service.isActive = await service._getIsActive();
    service.isEnabled = await service._getIsEnabled();
    service.status = await service._getStatus();
    return service;
  }

  Future<void> updateStatus() async {
    status = await _getStatus();
  }

  Future<void> restart() async {
    await _runAction('restart');
    isActive = await _getIsActive();
    status = await _getStatus();
  }

  Future<void> toggleActive() async {
    await _runAction(isActive ? 'stop' : 'start');
    isActive = await _getIsActive();
    status = await _getStatus();
  }

  Future<void> toggleEnabled() async {
    if (isEnabled && isActive) {
      await toggleActive();
    }
    await _runAction(isEnabled ? 'disable' : 'enable');
    isEnabled = await _getIsEnabled();
    status = await _getStatus();
  }

  Future<bool> _getIsActive() async {
    final activeStatus = await _runAction('is-active');
    return activeStatus == 'active';
  }

  Future<bool> _getIsEnabled() async {
    final enabledStatus = await _runAction('is-enabled');
    final status = enabledStatus.split('\n').last;
    return status == 'enabled';
  }

  Future<String> _getStatus() async {
    return await _runAction('status');
  }

  Future<String> _runAction(String action) async {
    return await runCommand('sudo systemctl ' + action + ' ' + name);
  }

  void save(String hostId) async {
    final prefs = await SharedPreferences.getInstance();
    _saveRef(id, hostId);
    prefs.setString('$id/name:', name);
    prefs.setString('$id/path:', path);
  }

  Future<void> remove(String hostId) async {
    final prefs = await SharedPreferences.getInstance();
    _removeRef(id, hostId);
    prefs.remove('$id/name:');
    prefs.remove('$id/path:');
  }

  static Future<Service?> get(
      String id, Future<String> Function(String) runCommand) async {
    final prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString('$id/name:');
    final String? path = prefs.getString('$id/path:');
    if (name != null && path != null) {
      return await Service.create(name, runCommand);
    }
    return null;
  }

  static Future<List<Service>> getList(
      String hostId, Future<String> Function(String) runCommand) async {
    final refList = await Service._getRefList(hostId);
    final futures = refList.map((id) => Service.get(id, runCommand));
    final Iterable<Service?> services = await Future.wait(futures);
    return services.whereType<Service>().toList();
  }

  void _saveRef(String id, String hostId) async {
    Ref ids = await Service._getRefList(hostId);
    if (!ids.contains(id)) {
      ids.add(id);
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('$hostId-services', ids);
    }
  }

  void _removeRef(String id, String hostId) async {
    Ref ids = await Service._getRefList(hostId);
    if (ids.contains(id)) {
      ids.remove(id);
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('$hostId-services', ids);
    }
  }

  static Future<Ref> _getRefList(String hostId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$hostId-services') ?? [];
  }
}
