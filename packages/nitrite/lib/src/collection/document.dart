import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/constants.dart';
import 'package:nitrite/src/common/tuples/pair.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// A representation of a nitrite document.
abstract class Document extends Iterable<Pair<String, dynamic>> {
  /// Creates a new empty document.
  static Document emptyDocument() => _NitriteDocument();

  /// Creates a new document initialized with the given key/value pair.
  static Document createDocument(String key, dynamic value) {
    var document = <String, dynamic>{};
    document[key] = value;
    return _NitriteDocument(document);
  }

  /// Creates a new document initialized with the given map.
  static Document createDocumentFromMap(Map<String, dynamic> map) {
    return _NitriteDocument(map);
  }

  /// Associates the specified value with the specified key in this document.
  ///
  /// NOTE: An embedded field is also supported.
  Document put(String key, dynamic value);

  /// Returns the value to which the specified key is associated with,
  /// or null if this document contains no mapping for the key.
  dynamic operator [](String key);

  /// Returns the value of type [T] to which the specified
  /// key is associated, or null if this document contains no mapping
  /// for the key.
  T? get<T>(String key);

  /// Return the nitrite id associated with this document.
  Future<NitriteId> get id;

  /// Retrieves all fields (top level and embedded) associated
  /// with this document.
  Set<String> get fields;

  /// Checks if this document has a nitrite id.
  bool get hasId;

  /// Removes the key and its value from the document.
  void remove(String key);

  /// Creates and returns a copy of this document.
  Document clone();

  /// Returns the number of entries in the document.
  int get size;

  /// Merges a document in this document.
  Document merge(Document document);

  /// Checks if a top level key exists in the document.
  bool containsKey(String key);

  /// Checks if a top level field or embedded field exists in the document.
  bool containsField(String field);

  /// Gets the document revision number.
  int get revision {
    if (!containsKey(Constants.docRevision)) {
      return 0;
    }
    return get<int>(Constants.docRevision)!;
  }

  /// Gets the source of this document.
  String get source {
    if (!containsKey(Constants.docSource)) {
      return "";
    }
    return get<String>(Constants.docSource)!;
  }

  /// Gets last modified time of this document since epoch.
  int get lastModifiedSinceEpoch {
    if (!containsKey(Constants.docModified)) {
      return 0;
    }
    return get<int>(Constants.docModified)!;
  }
}

class _NitriteDocument extends Document {
  static final List<String> _reservedFields = <String>[
    Constants.docId,
    Constants.docRevision,
    Constants.docSource,
    Constants.docModified,
  ];

  Map<String, dynamic> _documentMap = {};

  _NitriteDocument([Map<String, dynamic>? documentMap]) {
    if (documentMap != null) {
      _documentMap = documentMap;
    }
  }

  @override
  Document put(String field, dynamic value) {
    // field name cannot be empty or null
    if (field.isNullOrEmpty) {
      throw InvalidOperationException("Document does not support empty "
          "or null key.");
    }

    // field name cannot be empty or null
    if (identical(field, Constants.docId) && !NitriteId.validId(value)) {
      throw InvalidOperationException("_id is an auto generated value and"
          " cannot be set");
    }

    // if field name contains field separator, split the fields, and put the value
    // accordingly associated with th embedded field.
    if (_isEmbedded(field)) {
      var pattern = "\\${NitriteConfig.fieldSeparator}";
      var splits = field.split(pattern);
      _deepPut(splits, value);
    } else {
      _documentMap[field] = value;
    }

    return this;
  }

  @override
  operator [](String field) {
    if (_isEmbedded(field) && !containsKey(field)) {
      return _deepGet(field);
    }
    return _documentMap[field];
  }

  @override
  T? get<T>(String key) {
    return _documentMap[key] as T?;
  }

  @override
  Future<NitriteId> get id async {
    String idValue;

    // if _id field is not populated already, create a new id
    // and set, otherwise return the existing id
    if (!containsKey(Constants.docId)) {
      var id = await NitriteId.newId();
      idValue = id.idValue;
      _documentMap[Constants.docId] = idValue;
    } else {
      idValue = get<String>(Constants.docId)!;
    }

    return await NitriteId.createId(idValue);
  }

  @override
  Set<String> get fields => _getFieldsInternal("");

  @override
  bool get hasId => _documentMap.containsKey(Constants.docId);

  @override
  void remove(String field) {
    if (_isEmbedded(field)) {
      // if the field is an embedded field,
      // run a deep scan and remove the last field
      var splits = field.split("\\${NitriteConfig.fieldSeparator}");
      _deepRemove(splits);
    } else {
      _documentMap.remove(field);
    }
  }

  @override
  Document clone() {
    var cloned = {..._documentMap};

    // create the clone of any embedded documents as well
    cloned.forEach((key, value) {
      if (value is Document) {
        // this will recursively take care any embedded document
        // of the clone as well
        cloned[key] = value.clone();
      }
    });

    return _NitriteDocument(cloned);
  }

  @override
  Document merge(Document document) {
    if (document is _NitriteDocument) {
      _documentMap.addAll(document._documentMap);
    } else {
      throw InvalidOperationException(
          "Document merge only supports NitriteDocument");
    }
    return this;
  }

  @override
  bool containsKey(String key) => _documentMap.containsKey(key);

  @override
  bool containsField(String field) {
    if (containsKey(field)) {
      return true;
    } else {
      return fields.contains(field);
    }
  }

  @override
  operator ==(Object other) {
    if (identical(this, other) ||
        other is _NitriteDocument &&
            runtimeType == other.runtimeType &&
            _documentMap == other._documentMap) {
      return true;
    }

    if (other is! _NitriteDocument) {
      return false;
    }

    return DeepCollectionEquality.unordered()
        .equals(_documentMap, other._documentMap);
  }

  @override
  int get hashCode => DeepCollectionEquality.unordered()
      .hash(_documentMap);

  @override
  int get size => _documentMap.length;

  @override
  Iterator<Pair<String, dynamic>> get iterator => _PairIterator(_documentMap);

  bool _isEmbedded(String field) {
    return field.contains(NitriteConfig.fieldSeparator);
  }

  Set<String> _getFieldsInternal(String prefix) {
    throw UnimplementedError();
  }

  void _deepPut(List<String> splits, value) {
    throw UnimplementedError();
  }

  dynamic _deepGet(String field) {
    throw UnimplementedError();
  }

  void _deepRemove(List<String> splits) {
    throw UnimplementedError();
  }
}

class _PairIterator implements Iterator<Pair<String, dynamic>> {
  final Iterator<String> _keys;
  final Map<String, dynamic> _documentMap;

  _PairIterator(this._documentMap) : _keys = _documentMap.keys.iterator;

  @override
  Pair<String, dynamic> get current {
    var key = _keys.current;
    return Pair(key, _documentMap[key]);
  }

  @override
  bool moveNext() => _keys.moveNext();
}
