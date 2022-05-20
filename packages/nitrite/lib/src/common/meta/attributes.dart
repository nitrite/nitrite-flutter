import 'dart:collection';

import 'package:uuid/uuid.dart';

/// Represents metadata attributes of a collection.
class Attributes {
  static final String createdTime = "created_at";
  static final String lastModifiedTime = "last_modified_at";
  static final String owner = "owner";
  static final String uniqueId = "uuid";
  static final String syncLock = "sync_lock";
  static final String expiryWait = "expiry_wait";
  static final String tombstone = "tombstone";
  static final String feedLedger = "feed_ledger";
  static final String localCollectionMarker = "local_collection_marker";
  static final String remoteCollectionMarker = "remote_collection_marker";
  static final String localTombstoneMarker = "local_tombstone_marker";
  static final String remoteTombstoneMarker = "remote_tombstone_marker";
  static final String replica = "replica";
  
  Map<String, String> _attributes = {};

  /// Instantiates a new Attributes.
  Attributes([String? collection]) {
    _attributes = HashMap<String, String>();
    if (collection != null) {
      set(owner, collection);
    }
    set(createdTime, DateTime.now().millisecondsSinceEpoch.toString());
    var uuid = Uuid();
    set(uniqueId, uuid.v4());
  }

  /// Set attributes.
  Attributes set(String key, String value) {
    _attributes[key] = value;
    _attributes[lastModifiedTime] = DateTime.now()
        .millisecondsSinceEpoch.toString();
    return this;
  }

  /// Get string value of an attribute.
  String? operator [](String key) {
    return _attributes[key];
  }

  /// Check whether a key exists in the attributes.
  bool hasKey(String key) {
    return _attributes.containsKey(key);
  }
}
