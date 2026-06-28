import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:uuid/uuid.dart';

/// @nodoc
abstract class AttributesAware {
  Future<Attributes> getAttributes();

  Future<void> setAttributes(Attributes attributes);
}

/// Represents metadata attributes of a [NitriteMap].
class Attributes {
  static final String createdTime = "created_at";
  static final String lastModifiedTime = "last_modified_at";
  static final String owner = "owner";
  static final String uniqueId = "uuid";

  Map<String, String> _attributes = {};

  /// Instantiates a new [Attributes].
  Attributes([String? collection]) {
    _attributes = HashMap<String, String>();
    if (collection != null) {
      set(owner, collection);
    }
    set(createdTime, DateTime.now().millisecondsSinceEpoch.toString());
    var uuid = Uuid();
    set(uniqueId, uuid.v4());
  }

  /// Creates an instance of the Attributes class from a [Document] object.
  ///
  /// Args:
  ///   document (Document): The parameter "document" is of type "Document".
  ///
  /// Returns:
  ///   The method is returning an instance of the [Attributes] class.
  factory Attributes.fromDocument(Document document) {
    Attributes attr = Attributes();
    for (var pair in document) {
      if (pair.$1 != docId) {
        attr._attributes[pair.$1] = pair.$2;
      }
    }
    return attr;
  }

  /// Adds a key-value pair to the attributes and returns
  /// the updated [Attributes] object.
  ///
  /// Args:
  ///   key (String): The key parameter is a string that represents the
  /// name of the attribute.
  ///   value (String): The value parameter is a string that represents
  /// the value to be associated with the given key.
  ///
  /// Returns:
  ///   The method is returning an object of type [Attributes].
  Attributes set(String key, String value) {
    _attributes[key] = value;
    _attributes[lastModifiedTime] =
        DateTime.now().millisecondsSinceEpoch.toString();
    return this;
  }

  /// Retrieves the value associated with a given key from a [Attributes].
  String? operator [](String key) {
    return _attributes[key];
  }

  /// Check whether a key exists in the attributes.
  bool hasKey(String key) {
    return _attributes.containsKey(key);
  }

  Document toDocument() => documentFromMap(_attributes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attributes &&
          runtimeType == other.runtimeType &&
          MapEquality<String, String>().equals(_attributes, other._attributes);

  @override
  int get hashCode => MapEquality<String, String>().hash(_attributes);

  @override
  String toString() {
    return 'Attributes{_attributes: $_attributes}';
  }
}
