import 'package:encrypt/encrypt.dart';
import 'package:nitrite/nitrite.dart';

/// A processor class which is responsible for encrypting and
/// decrypting string fields in a Nitrite database document.
class StringFieldEncryptionProcessor extends Processor {
  final _iv = IV.fromLength(16);
  late final Key _key;
  late final Encrypter _encryptor;

  final List<String> fields = [];

  /// Creates a new instance of the [StringFieldEncryptionProcessor] class.
  ///
  /// If [password] is not provided, a random key will be generated.
  StringFieldEncryptionProcessor([String? password]) {
    _key = password == null || password.isEmpty
        ? Key.fromLength(32)
        : Key.fromUtf8(password);
    _encryptor = Encrypter(AES(_key));
  }

  /// Adds one or more field names to the list of fields that
  /// should be encrypted.
  void addFields(List<String> fields) {
    this.fields.addAll(fields);
  }

  /// Processes the document after reading from the database. Decrypts the
  /// encrypted fields and returns a new document with decrypted values.
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

  /// Processes the document before writing to the database. Encrypts the values
  /// of the specified fields using the provided encryptor.
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

  String _encrypt(String plainText) {
    return _encryptor.encrypt(plainText, iv: _iv).base64;
  }

  String _decrypt(String encrypted) {
    return _encryptor.decrypt64(encrypted, iv: _iv);
  }
}
