import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart' show SSHKeyPair, SSHPem;
import 'package:uuid/uuid.dart';

import 'package:flush/model/encodable.dart' show Ref;

typedef SavedPrivateKeys = List<PrivateKey>;

class PrivateKey {
  late String id;
  final String name;
  late String type;
  final String pemText;
  late bool isEncrypted;
  final String? passphrase;

  PrivateKey._({
    required this.name,
    required this.pemText,
    this.passphrase,
  });

  static PrivateKey create(
      {String? id,
      required String name,
      required String pemText,
      String? passphrase}) {
    final key =
        PrivateKey._(name: name, pemText: pemText, passphrase: passphrase);
    key.id = id ?? const Uuid().v4();
    try {
      key.isEncrypted = SSHKeyPair.isEncryptedPem(pemText);
      if (key.isEncrypted && (passphrase == null || passphrase.isEmpty)) {
        throw 'No passphrase provided';
      }
      key.type = SSHPem.decode(pemText).type;
      return key;
    } on FormatException catch (e) {
      throw e.message;
    } catch (e) {
      throw e.toString();
    }
  }

  void save() async {
    final prefs = await SharedPreferences.getInstance();
    _saveRef(id);
    prefs.setString('$id/name:', name);
    prefs.setString('$id/pemText:', pemText);
    if (passphrase != null) {
      prefs.setString('$id/passphrase:', passphrase!);
    }
  }

  void remove() async {
    final prefs = await SharedPreferences.getInstance();
    _removeRef(id);
    prefs.remove('$id/name:');
    prefs.remove('$id/pemText:');
    prefs.remove('$id/passphrase:');
  }

  static Future<PrivateKey?> get(String? id) async {
    if (id == null) return null;
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('$id/name:');
    String? pemText = prefs.getString('$id/pemText:');
    String? passphrase = prefs.getString('$id/passphrase:');
    if (name != null && pemText != null) {
      return PrivateKey.create(
        id: id,
        name: name,
        pemText: pemText,
        passphrase: passphrase,
      );
    }
    return null;
  }

  static Future<SavedPrivateKeys> getList() async {
    final refList = await PrivateKey._getRefList();
    final futures = refList.map((id) => PrivateKey.get(id));
    final Iterable<PrivateKey?> privateKeys = await Future.wait(futures);
    return privateKeys.whereType<PrivateKey>().toList();
  }

  void _saveRef(String id) async {
    Ref ids = await PrivateKey._getRefList();
    if (!ids.contains(id)) {
      ids.add(id);
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('privateKeys', ids);
    }
  }

  void _removeRef(String id) async {
    Ref ids = await PrivateKey._getRefList();
    if (ids.contains(id)) {
      ids.remove(id);
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('privateKeys', ids);
    }
  }

  static Future<Ref> _getRefList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('privateKeys') ?? [];
  }
}
