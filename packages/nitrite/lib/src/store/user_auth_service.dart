import 'package:crypt/crypt.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/store/user_credential.dart';

/// @nodoc
class UserAuthenticationService {
  final NitriteStore _nitriteStore;

  UserAuthenticationService(this._nitriteStore);

  Future<void> authenticate(String? username, String? password) async {
    var existing = await _nitriteStore.hasMap(userMap);
    if (!password.isNullOrEmpty && !username.isNullOrEmpty) {
      if (!existing) {
        var hash = _hash(password!);

        var userCredential = UserCredential(hash);
        var uMap = await _nitriteStore.openMap<String, Document>(userMap);
        await uMap.put(username!, userCredential.toDocument());
      } else {
        var uMap = await _nitriteStore.openMap<String, Document>(userMap);
        var doc = await uMap[username!];
        if (doc != null) {
          var userCredential = UserCredential.fromDocument(doc);
          var expectedHash = userCredential.passwordHash;
          var crypt = Crypt(expectedHash);

          if (!crypt.match(password!)) {
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
        var expectedHash = userCredential.passwordHash;
        var crypt = Crypt(expectedHash);

        if (!crypt.match(oldPassword)) {
          throw NitriteSecurityException('Username or password is invalid');
        }
      }
    } else {
      if (await _nitriteStore.hasMap(userMap)) {
        throw NitriteSecurityException('Username or password is invalid');
      }
    }

    uMap ??= await _nitriteStore.openMap<String, Document>(userMap);

    var hash = _hash(newPassword);
    var userCredential = UserCredential(hash);
    await uMap.put(username, userCredential.toDocument());
  }

  String _hash(String password) {
    final hash = Crypt.sha256(password);
    return hash.toString();
  }
}
