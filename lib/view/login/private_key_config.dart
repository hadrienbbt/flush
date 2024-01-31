import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart' show SSHKeyPair;
import 'package:provider/provider.dart';

import 'package:flush/controller/login_controller.dart';
import 'package:flush/model/credentials.dart';
import 'package:flush/model/private_key.dart';

class KeyConfig extends StatefulWidget {
  final Credentials? credentials;

  const KeyConfig({Key? key, this.credentials}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _KeyConfigState();
}

class _KeyConfigState extends State<KeyConfig> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();

  bool _isEncryptedPrivateKey = false;
  bool _showPassphrase = false;

  @override
  void initState() {
    super.initState();
    final c = widget.credentials;
    if (c != null) {
      _keyController.text = c.key.pemText;
      if (c.key.passphrase != null) {
        _passphraseController.text = c.key.passphrase!;
      }
      _onKeyChange();
    }
    _keyController.addListener(_onKeyChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  bool _isEncrypted(String key) {
    try {
      final isEncrypted = SSHKeyPair.isEncryptedPem(key);
      return isEncrypted;
    } catch (e) {
      return false;
    }
  }

  void _onKeyChange() {
    bool isEncrypted = _isEncrypted(_keyController.text);
    setState(() {
      _isEncryptedPrivateKey = isEncrypted;
    });
  }

  void _toggleShowPassphrase() {
    setState(() {
      _showPassphrase = !_showPassphrase;
    });
  }

  @override
  Widget build(BuildContext context) {
    void _showToast(BuildContext context, String errorMessage) {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          action: SnackBarAction(
              label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
        ),
      );
    }

    void _onPressAdd() async {
      try {
        final privateKey = PrivateKey.create(
            name: _nameController.text.trim(),
            pemText: _keyController.text.trim(),
            passphrase: _passphraseController.text.trim());
        privateKey.save();
        LoginController loginController =
            Provider.of<LoginController>(context, listen: false);

        loginController.setPrivateKey(privateKey);
        Navigator.pop(context);
      } catch (e) {
        _showToast(context, e.toString());
      }
    }

    Widget renderContent() {
      List<Widget> column = [
        TextField(
            controller: _nameController,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Key Name',
              suffixIcon: Icon(Icons.numbers),
            )),
        const SizedBox(height: 10),
        TextField(
            controller: _keyController,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 6,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Pem text',
              suffixIcon: Icon(Icons.key),
            )),
        const SizedBox(height: 10),
      ];

      if (_isEncryptedPrivateKey) {
        column.addAll([
          TextField(
              controller: _passphraseController,
              autocorrect: false,
              enableSuggestions: false,
              obscureText: !_showPassphrase,
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                labelText: 'Passphrase',
                suffixIcon: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround, // added line
                    mainAxisSize: MainAxisSize.min, // added line
                    children: [
                      IconButton(
                          onPressed: _toggleShowPassphrase,
                          icon: Icon(_showPassphrase
                              ? Icons.visibility_off
                              : Icons.visibility)),
                      const SizedBox(width: 10),
                      const Icon(Icons.password)
                    ]),
              )),
          const SizedBox(height: 10)
        ]);
      }

      column.addAll([
        const SizedBox(height: 40),
        TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('ADD KEY', style: TextStyle(color: Colors.white)),
            onPressed: _onPressAdd),
        const SizedBox(height: 10),
      ]);

      return Column(
        children: column,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.credentials?.id ?? 'Add Private Key'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: renderContent(),
          ),
        ),
      ),
    );
  }
}
