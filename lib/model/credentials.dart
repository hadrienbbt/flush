import 'package:shared_preferences/shared_preferences.dart';
import 'package:flush/model/host.dart';
import 'package:flush/model/private_key.dart';
import 'package:flush/model/encodable.dart' show Ref;
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

typedef SavedCredentials = List<Credentials>;

class Credentials {
  late String id;
  final Host host;
  final PrivateKey? key;

  Credentials({
    required this.host,
    this.key,
  }) {
    final hostId = host.id;
    final keyId = key?.id;
    id = '$hostId:$keyId';
  }

  void save() async {
    final prefs = await SharedPreferences.getInstance();
    _saveRef(id);
    prefs.setString('$id/host:', host.id);
    if (key != null) {
      prefs.setString('$id/key:', key!.id);
    }
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
    if (hostId == null) return null;
    final Host? host = await Host.get(hostId);
    final PrivateKey? key = await PrivateKey.get(keyId);
    if (host == null) return null;
    return Credentials(host: host, key: key);
  }

  static bool _deduplicate(
      Credentials credentials, List<Credentials> savedCredentials) {
    if (credentials.key != null) return true;
    Credentials? existingCred = savedCredentials.firstWhereOrNull(
        (saved) => credentials.host.id == saved.host.id && saved.key != null);
    return existingCred == null;
  }

  static Future<SavedCredentials> getList() async {
    final refList = await Credentials._getRefList();
    final futures = refList.map((id) => Credentials.get(id));
    final Iterable<Credentials?> credentials = await Future.wait(futures);
    List<Credentials> savedCredentials =
        credentials.whereType<Credentials>().toList();
    savedCredentials.sort((a, b) => a.host.name.compareTo(b.host.name));
    return savedCredentials
        .where((saved) => Credentials._deduplicate(saved, savedCredentials))
        .toList();
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
