import 'package:nitrite/src/common/constants.dart';
import 'package:nitrite/src/common/initializable.dart';
import 'package:nitrite/src/common/meta/attributes.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

import 'package:nitrite/nitrite.dart';

/// Represents a Nitrite key-value pair map. Every piece of
/// data in a Nitrite database is stored in [NitriteMap].
abstract class NitriteMap<Key, Value> extends AttributesAware
    implements Initializable {
  /// Determines if the map contains a mapping for the
  /// specified key.
  Future<bool> containsKey(Key key);

  /// Gets the value mapped with the specified key or [null] otherwise.
  Future<Value?> operator [](Key key);

  /// Removes all entries in the map.
  Future<void> clear();

  /// Closes this [NitriteMap].
  Future<void> close();

  /// Indicates if this [NitriteMap] is closed.
  bool get isClosed;

  /// Gets a [Stream] of the values contained in
  /// this map.
  Stream<Value> values();

  /// Gets a [Stream] of the keys contained in this map.
  Stream<Key> keys();

  /// Removes the mapping for a key from this map if it is present.
  Future<Value?> remove(Key key);

  /// Associates the specified value with the specified key in this map.
  /// If the map previously contained a mapping for
  /// the key, the old value is replaced by the specified value.
  Future<void> put(Key key, Value value);

  /// Get the number of entries, as an integer. 0x7fffffffffffffff is returned if
  /// there are more than these entries.
  Future<int> size();

  /// Add a key-value pair if it does not yet exist.
  Future<Value?> putIfAbsent(Key key, Value value);

  /// Get the lest key that is greater than the given key, or null if no
  /// such key exists.
  Future<Key?> higherKey(Key key);

  /// Get the least key that is greater than or equal to this key.
  Future<Key?> ceilingKey(Key key);

  /// Get the largest key that is smaller than the given key, or null if no
  /// such key exists.
  Future<Key?> lowerKey(Key key);

  /// Get the largest key that is smaller or equal to this key.
  Future<Key?> floorKey(Key key);

  /// Indicates whether the map is empty.
  Future<bool> isEmpty();

  /// Gets the parent {@link NitriteStore} where this map is stored.
  NitriteStore<Config> getStore<Config extends StoreConfig>();

  /// Gets name of this map.
  String get name;

  /// Gets a [Stream] of the mappings contained in this map.
  Stream<Pair<Key, Value>> entries();

  /// Gets a reversed [Stream] of the mappings
  /// contained in this map.
  Stream<Pair<Key, Value>> reversedEntries();

  /// Deletes the map from the store.
  Future<void> drop();

  /// Indicates if this map is dropped.
  bool get isDropped;

  /// Gets the attributes of this map.
  @override
  Future<Attributes> getAttributes() async {
    if (!isDropped) {
      NitriteMap<String, Attributes> metaMap =
          await getStore().openMap(metaMapName);

      if (name != metaMapName) {
        var attributes = await metaMap[name];
        if (attributes != null) {
          return attributes;
        } else {
          return Attributes();
        }
      }
    }
    return Attributes();
  }

  /// Sets the attributes for this map.
  @override
  Future<void> setAttributes(Attributes attributes) async {
    if (!isDropped) {
      var metaMap = await getStore().openMap<String, Attributes>(metaMapName);

      if (name != metaMapName) {
        await metaMap.put(name, attributes);
      }
    }
  }

  /// Update last modified time of the map.
  Future<void> updateLastModifiedTime() async {
    if (!isDropped) {
      if (name.isNullOrEmpty || name == metaMapName) {
        return;
      }

      var metaMap = await getStore().openMap<String, Attributes>(metaMapName);

      var attributes = await metaMap[name];
      if (attributes == null) {
        attributes = Attributes(name);
        metaMap.put(name, attributes);
      }

      attributes.set(Attributes.lastModifiedTime,
          DateTime.now().millisecondsSinceEpoch.toString());
    }
  }
}
