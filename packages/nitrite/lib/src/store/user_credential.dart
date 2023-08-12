import 'package:nitrite/nitrite.dart';

class UserCredential {
  String _passwordHash;

  factory UserCredential.fromDocument(Document document) {
    var passwordHash = document.get('passwordHash');
    return UserCredential(passwordHash);
  }

  UserCredential(this._passwordHash);

  String get passwordHash => _passwordHash;

  Document toDocument() {
    return emptyDocument()..put('passwordHash', _passwordHash);
  }
}
