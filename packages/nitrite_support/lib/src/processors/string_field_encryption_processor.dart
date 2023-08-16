import 'package:encrypt/encrypt.dart';
import 'package:nitrite/nitrite.dart';

final _key = Key.fromLength(32);
final _iv = IV.fromLength(16);
final _encryptor = Encrypter(AES(_key));

class StringFieldEncryptionProcessor extends Processor {
  final List<String> fields = [];

  void addFields(List<String> fields) {
    this.fields.addAll(fields);
  }

  @override
  Future<Document> processAfterRead(Document document) async {
    var copy = document.clone();
    for (var field in fields) {
      var value = copy.get<String>(field);
      if (value != null && value.isNotEmpty) {
        value = _decrypt(value);
        copy[field] = value;
      }
    }
    return copy;
  }

  @override
  Future<Document> processBeforeWrite(Document document) async {
    var copy = document.clone();
    for (var field in fields) {
      var value = copy.get<String>(field);
      if (value != null && value.isNotEmpty) {
        value = _encrypt(value);
        copy[field] = value;
      }
    }
    return copy;
  }
}

String _encrypt(String plainText) {
  return _encryptor.encrypt(plainText, iv: _iv).base64;
}

String _decrypt(String encrypted) {
  return _encryptor.decrypt64(encrypted, iv: _iv);
}
