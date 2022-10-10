import 'package:nitrite/nitrite.dart';

class UserCredential {
  List<int> _passwordHash;
  List<int> _passwordSalt;

  factory UserCredential.fromDocument(Document document) {
    var passwordHash = document.get('passwordHash');
    var passwordSalt = document.get('passwordSalt');
    return UserCredential(passwordHash, passwordSalt);
  }

  UserCredential(this._passwordHash, this._passwordSalt);

  List<int> get passwordHash => _passwordHash;
  List<int> get passwordSalt => _passwordSalt;

  Document toDocument() {
    return Document.emptyDocument()
      ..put('passwordHash', _passwordHash)
      ..put('passwordSalt', _passwordSalt);
  }
}

