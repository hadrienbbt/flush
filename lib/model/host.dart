import 'package:shared_preferences/shared_preferences.dart';
import 'package:flush/model/encodable.dart' show Ref;

typedef SavedHosts = List<Host>;

class Host {
  late String id;
  final String name;
  final int? port;
  final String user;

  Host({
    required this.name,
    required this.port,
    required this.user,
  }) {
    id = '$user@$name';
  }

  void save() async {
    final prefs = await SharedPreferences.getInstance();
    _saveRef(id);
    prefs.setString('$id/hostname:', name);
    prefs.setString('$id/username:', user);
    if (port != null) {
      prefs.setInt('$id/port:', port!);
    }
  }

  void remove() async {
    final prefs = await SharedPreferences.getInstance();
    _removeRef(id);
    prefs.remove('$id/hostname:');
    prefs.remove('$id/username:');
    prefs.remove('$id/port:');
  }

  static Future<Host?> get(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString('$id/hostname:');
    final int? port = prefs.getInt('$id/port:');
    final String? user = prefs.getString('$id/username:');
    if (name != null && user != null) {
      return Host(
        name: name,
        port: port,
        user: user,
      );
    }

    return null;
  }

  static Future<SavedHosts> getList() async {
    final refList = await Host._getRefList();
    final futures = refList.map((id) => Host.get(id));
    final Iterable<Host?> hosts = await Future.wait(futures);
    return hosts.whereType<Host>().toList();
  }

  void _saveRef(String id) async {
    Ref ids = await Host._getRefList();
    if (!ids.contains(id)) {
      ids.add(id);
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('hosts', ids);
    }
  }

  void _removeRef(String id) async {
    Ref ids = await Host._getRefList();
    if (ids.contains(id)) {
      ids.remove(id);
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('hosts', ids);
    }
  }

  static Future<Ref> _getRefList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('hosts') ?? [];
  }
}
