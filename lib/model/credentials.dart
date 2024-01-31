import 'package:shared_preferences/shared_preferences.dart';
import 'package:flush/model/host.dart';
import 'package:flush/model/private_key.dart';
import 'package:flush/model/encodable.dart' show Ref;

typedef SavedCredentials = List<Credentials>;

class Credentials {
  late String id;
  final Host host;
  final PrivateKey key;

  Credentials({
    required this.host,
    required this.key,
  }) {
    final hostId = host.id;
    final keyId = key.id;
    id = '$hostId:$keyId';
  }

  void save() async {
    final prefs = await SharedPreferences.getInstance();
    _saveRef(id);
    prefs.setString('$id/host:', host.id);
    prefs.setString('$id/key:', key.id);
    host.save();
  }

  void remove() async {
    final prefs = await SharedPreferences.getInstance();
    _removeRef(id);
    prefs.remove('$id/host:');
    prefs.remove('$id/key:');
    host.remove();
  }

  static Future<Credentials?> get(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? hostId = prefs.getString('$id/host:');
    final String? keyId = prefs.getString('$id/key:');
    if (hostId == null || keyId == null) return null;
    final Host? host = await Host.get(hostId);
    final PrivateKey? key = await PrivateKey.get(keyId);
    if (host == null || key == null) return null;
    return Credentials(host: host, key: key);
  }

  static Future<SavedCredentials> getList() async {
    final refList = await Credentials._getRefList();
    final futures = refList.map((id) => Credentials.get(id));
    final Iterable<Credentials?> credentials = await Future.wait(futures);
    return credentials.whereType<Credentials>().toList();
  }

  void _saveRef(String id) async {
    Ref ids = await Credentials._getRefList();
    if (!ids.contains(id)) {
      ids.add(id);
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('credentials', ids);
    }
  }

  void _removeRef(String id) async {
    Ref ids = await Credentials._getRefList();
    if (ids.contains(id)) {
      ids.remove(id);
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('credentials', ids);
    }
  }

  static Future<Ref> _getRefList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('credentials') ?? [];
  }
}
