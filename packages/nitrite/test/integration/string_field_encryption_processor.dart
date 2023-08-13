import 'package:nitrite/nitrite.dart';
import 'package:encrypt/encrypt.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

final key = Key.fromLength(32);
final iv = IV.fromLength(16);
final encrypter = Encrypter(AES(key));

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
      if (!value.isNullOrEmpty) {
        value = _decrypt(value!);
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
      if (!value.isNullOrEmpty) {
        value = _encrypt(value!);
        copy[field] = value;
      }
    }
    return copy;
  }
}

String _encrypt(String plainText) {
  return encrypter.encrypt(plainText, iv: iv).base64;
}

String _decrypt(String encrypted) {
  return encrypter.decrypt64(encrypted, iv: iv);
}
