import 'package:nitrite/nitrite.dart';

class UserCredential implements Mappable {
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

  @override
  void read(NitriteMapper? mapper, Document document) {
    _passwordHash = document.get('passwordHash');
    _passwordSalt = document.get('passwordSalt');
  }

  @override
  Document write(NitriteMapper? mapper) {
    return Document.emptyDocument()
      ..put('passwordHash', _passwordHash)
      ..put('passwordSalt', _passwordSalt);
  }
}
