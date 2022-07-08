import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/store/user_credential.dart';

class UserAuthenticationService {
  final Random _random = Random.secure();
  final NitriteStore _nitriteStore;

  UserAuthenticationService(this._nitriteStore);

  Future<void> authenticate(String? username, String? password) async {
    var existing = await _nitriteStore.hasMap(userMap);
    if (!password.isNullOrEmpty && !username.isNullOrEmpty) {
      if (!existing) {
        var salt = _getNextSalt();
        var hash = await _hash(password!, salt);

        var userCredential = UserCredential(hash, salt);
        var uMap = await _nitriteStore.openMap<String, Document>(userMap);
        await uMap.put(username!, userCredential.write(null));
      } else {
        var uMap = await _nitriteStore.openMap<String, Document>(userMap);
        var doc = await uMap[username!];
        if (doc != null) {
          var userCredential = UserCredential.fromDocument(doc);
          var salt = userCredential.passwordSalt;
          var expectedHash = userCredential.passwordHash;

          if (await _notExpectedPassword(password!, salt, expectedHash)) {
            throw NitriteSecurityException('Username or password is invalid');
          }
        } else {
          throw NitriteSecurityException('Username or password is invalid');
        }
      }
    } else if (existing) {
      throw NitriteSecurityException('Username or password is invalid');
    }
  }

  Future<void> addOrUpdatePassword(bool update, String username,
      String oldPassword, String newPassword) async {
    NitriteMap<String, Document>? uMap;

    if (update) {
      uMap = await _nitriteStore.openMap<String, Document>(userMap);
      var doc = await uMap[username];
      if (doc != null) {
        var userCredential = UserCredential.fromDocument(doc);
        var salt = userCredential.passwordSalt;
        var expectedHash = userCredential.passwordHash;

        if (await _notExpectedPassword(oldPassword, salt, expectedHash)) {
          throw NitriteSecurityException('Username or password is invalid');
        }
      }
    } else {
      if (await _nitriteStore.hasMap(userMap)) {
        throw NitriteSecurityException('Username or password is invalid');
      }
    }

    uMap ??= await _nitriteStore.openMap<String, Document>(userMap);

    var salt = _getNextSalt();
    var hash = await _hash(newPassword, salt);
    var userCredential = UserCredential(hash, salt);
    await uMap.put(username, userCredential.write(null));
  }

  List<int> _getNextSalt() {
    var salt = <int>[];
    for (var i = 0; i < 16; i++) {
      salt.add(_random.nextInt(256));
    }
    return salt;
  }

  Future<List<int>> _hash(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 128,
    );

    var secretKey = SecretKey(utf8.encode(password));
    var newSecretKey =
        await pbkdf2.deriveKey(secretKey: secretKey, nonce: salt);
    return newSecretKey.extractBytes();
  }

  Future<bool> _notExpectedPassword(
      String password, List<int> salt, List<int> expectedHash) async {
    var pwdHash = await _hash(password, salt);
    if (pwdHash.length != expectedHash.length) return true;
    for (var i = 0; i < pwdHash.length; i++) {
      if (pwdHash[i] != expectedHash[i]) return true;
    }
    return false;
  }
}
