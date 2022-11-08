import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

Document emptyDocument() => Document.emptyDocument();

Document documentFromMap(Map<String, dynamic> map) => Document.fromMap(map);

Document createDocument(String key, dynamic value) =>
    Document.createDocument(key, value);

/// A representation of a nitrite document.
abstract class Document extends Iterable<Pair<String, dynamic>> {
  /// Creates a new empty document.
  static Document emptyDocument() => _NitriteDocument();

  /// Creates a new document initialized with the given key/value pair.
  static Document createDocument(String key, dynamic value) {
    var document = emptyDocument();
    document.put(key, value);
    return document;
  }

  /// Creates a new document initialized with the given map.
  static Document fromMap(Map<String, dynamic> map) {
    var doc = emptyDocument();
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        doc.put(key, fromMap(value));
      } else {
        doc.put(key, value);
      }
    });
    return doc;
  }

  /// Associates the specified value with the specified key in this document.
  ///
  /// NOTE: An embedded field is also supported.
  Document put(String key, dynamic value);

  /// Returns the value to which the specified key is associated with,
  /// or null if this document contains no mapping for the key.
  dynamic operator [](String key);

  /// Associates the specified value with the specified key in this document.
  ///
  /// NOTE: An embedded field is also supported.
  void operator []=(String key, dynamic value) {
    put(key, value);
  }

  /// Returns the value of type [T] to which the specified
  /// key is associated, or null if this document contains no mapping
  /// for the key.
  T? get<T>(String key);

  /// Return the nitrite id associated with this document.
  NitriteId get id;

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
    if (!containsKey(docRevision)) {
      return 0;
    }
    return get<int>(docRevision)!;
  }

  /// Gets the source of this document.
  String get source {
    if (!containsKey(docSource)) {
      return "";
    }
    return get<String>(docSource)!;
  }

  /// Gets last modified time of this document since epoch.
  int get lastModifiedSinceEpoch {
    if (!containsKey(docModified)) {
      return 0;
    }
    return get<int>(docModified)!;
  }
}

class _NitriteDocument extends Document {
  static final List<String> _reservedFields = <String>[
    docId,
    docRevision,
    docSource,
    docModified,
  ];

  final Map<String, dynamic> _documentMap = {};

  _NitriteDocument();

  @override
  Document put(String field, dynamic value) {
    // field name cannot be empty or null
    if (field.isNullOrEmpty) {
      throw InvalidOperationException("Document does not support empty "
          "or null key.");
    }

    // field name cannot be empty or null
    if (field == docId && !NitriteId.validId(value)) {
      throw InvalidOperationException("_id is an auto generated value and"
          " cannot be set");
    }

    // if field name contains field separator, split the fields, and put the value
    // accordingly associated with th embedded field.
    if (_isEmbedded(field)) {
      var pattern = NitriteConfig.fieldSeparator;
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
    return this[key] as T?;
  }

  @override
  NitriteId get id {
    String idValue;

    // if _id field is not populated already, create a new id
    // and set, otherwise return the existing id
    if (!containsKey(docId)) {
      var id = NitriteId.newId();
      idValue = id.idValue;
      _documentMap[docId] = idValue;
    } else {
      idValue = get<String>(docId)!;
    }

    return NitriteId.createId(idValue);
  }

  @override
  Set<String> get fields => _getFieldsInternal("");

  @override
  bool get hasId => _documentMap.containsKey(docId);

  @override
  void remove(String field) {
    if (_isEmbedded(field)) {
      // if the field is an embedded field,
      // run a deep scan and remove the last field
      var splits = field.split(NitriteConfig.fieldSeparator);
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

    var newDoc = _NitriteDocument();
    newDoc._documentMap.addAll(cloned);
    return newDoc;
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
  int get hashCode => DeepCollectionEquality.unordered().hash(_documentMap);

  @override
  int get size => _documentMap.length;

  @override
  Iterator<Pair<String, dynamic>> get iterator => _PairIterator(_documentMap);

  bool _isEmbedded(String field) {
    return field.contains(NitriteConfig.fieldSeparator);
  }

  Set<String> _getFieldsInternal(String prefix) {
    var fields = <String>{};

    // iterate top level keys
    for (var pair in _documentMap.entries) {
      // ignore the reserved fields
      if (_reservedFields.contains(pair.key)) continue;

      var value = pair.value;
      if (value is _NitriteDocument) {
        // if the value is a document, traverse its fields recursively,
        // prefix would be the field name of the document
        if (prefix.isNullOrEmpty) {
          // level-1 fields
          fields.addAll(value._getFieldsInternal(pair.key));
        } else {
          // level-n fields, separated by field separator
          fields.addAll(value._getFieldsInternal("$prefix"
              "${NitriteConfig.fieldSeparator}${pair.key}"));
        }
      } else if (value is! Iterable) {
        // if there is no more embedded document, add the field to the list
        // and if this is an embedded document then prefix its name by parent fields,
        // separated by field separator
        if (prefix.isNullOrEmpty) {
          fields.add(pair.key);
        } else {
          fields.add("$prefix${NitriteConfig.fieldSeparator}${pair.key}");
        }
      }
    }
    return fields;
  }

  dynamic _deepGet(String field) {
    if (_isEmbedded(field)) {
      return _getByEmbeddedKey(field);
    } else {
      return null;
    }
  }

  void _deepPut(List<String> splits, dynamic value) {
    if (splits.isEmpty) {
      throw ValidationException("Invalid key provided");
    }

    var key = splits[0];
    if (splits.length == 1) {
      // if last key, simply put in the current document
      put(key, value);
    } else {
      // get the object for the current level
      var object = this[key];

      // get the remaining embedded fields for next level scan
      var remainingSplits = splits.sublist(1);

      if (object is _NitriteDocument) {
        // if the current level value is embedded doc, scan to the next level
        object._deepPut(remainingSplits, value);
      } else if (object == null) {
        // if current level value is null, create a new document
        // and try to create next level embedded doc by next level scan
        var newDoc = _NitriteDocument();
        newDoc._deepPut(remainingSplits, value);

        // put the newly created document in current level
        put(key, newDoc);
      }
    }
  }

  void _deepRemove(List<String> splits) {
    if (splits.isEmpty) {
      throw ValidationException("Invalid key provided");
    }

    var key = splits[0];
    if (splits.length == 1) {
      // if last key, simply remove from the current document
      remove(key);
    } else {
      // get the object for the current level
      var value = this[key];

      // get the remaining embedded fields for next level scan
      var remainingSplits = splits.sublist(1);

      if (value is _NitriteDocument) {
        // if the current level value is embedded doc, scan to the next level
        value._deepRemove(remainingSplits);
        if (value.isEmpty) {
          // if the next level document is an empty one
          // remove the current level document also
          _documentMap.remove(key);
        }
      } else if (value is List) {
        if (_isInteger(splits[1])) {
          // if the current level value is an iterable,
          // remove the element at the next level
          var index = _asInteger(splits[1]);
          var item = value.elementAt(index);
          if (splits.length > 2 && item is _NitriteDocument) {
            // if there are more splits, then this is an embedded document
            // so remove the element at the next level
            item._deepRemove(remainingSplits.sublist(1));
          } else {
            // if there are no more splits, then this is a primitive value
            // so remove the element at the next level
            value.removeAt(index);
            _documentMap[key] = value;
          }
        }
      } else {
        // if current level value is null, remove the key
        _documentMap.remove(key);
      }
    }
  }

  dynamic _getByEmbeddedKey(String embeddedKey) {
    var path = embeddedKey.split(NitriteConfig.fieldSeparator);

    // split the key
    if (path.isEmpty) {
      return null;
    }

    // get current level value and scan to next level using remaining keys
    return _recursiveGet(this[path[0]], path.sublist(1));
  }

  dynamic _recursiveGet(dynamic value, List<String> splits) {
    if (value == null) {
      return null;
    }

    if (splits.isEmpty) {
      return value;
    }

    if (value is _NitriteDocument) {
      // if the current level value is document, scan to the next level with remaining keys
      return _recursiveGet(value[splits[0]], splits.sublist(1));
    }

    if (value is Iterable) {
      // if the current level value is an iterable

      // get the first key
      var key = splits[0];
      if (_isInteger(key)) {
        // if the current key is an integer
        int index = _asInteger(key);

        // check index lower bound
        if (index < 0) {
          throw ValidationException("Invalid index $index to access item "
              "inside a document");
        }

        // check index upper bound
        if (index >= value.length) {
          throw ValidationException("Invalid index $index to access item "
              "inside a document");
        }

        // get the value at the index from the list
        // if there are remaining keys, scan to the next level
        return _recursiveGet(value.elementAt(index), splits.sublist(1));
      } else {
        // if the current key is not an integer, then decompose the
        // list and scan each of the element of the
        // list using remaining keys and return a list of all returned
        // elements from each of the list items.
        return _decompose(value, splits);
      }
    }

    // if no match found return null
    return null;
  }

  List<dynamic> _decompose(Iterable value, List<String> splits) {
    var items = <dynamic>{};

    // iterate each item
    for (var item in value) {
      // scan the item using remaining keys
      var result = _recursiveGet(item, splits);

      if (result != null) {
        if (result is Iterable) {
          // if the result is an iterable, add all items to the list
          items.addAll(result);
        } else {
          // if the result is not an iterable, add the result to the list
          items.add(result);
        }
      }
    }

    return items.toList();
  }

  bool _isInteger(String value) {
    if (value.isNullOrEmpty) {
      return false;
    }
    return int.tryParse(value) != null;
  }

  int _asInteger(String value) {
    var result = int.tryParse(value);
    if (result == null) return -1;
    return result;
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
