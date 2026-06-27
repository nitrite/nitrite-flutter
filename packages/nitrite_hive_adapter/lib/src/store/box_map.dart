// ignore_for_file: implementation_imports

import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/splay_tree_extensions.dart';
import 'package:nitrite_hive_adapter/src/store/hive_store.dart';
import 'package:nitrite_hive_adapter/src/store/key_encoder.dart';

/// @nodoc
class BoxMap<Key, Value> extends NitriteMap<Key, Value> {
  final String _mapName;
  final LazyBox _lazyBox;
  final HiveStore _store;
  final KeyComparator _keyComparator;
  final KeyCodec _keyCodec;
  bool _dropped = false;
  bool _closed = false;

  /// Decoded keys kept sorted by [_keyComparator] so ordered navigation
  /// (`ceilingKey`, range scans, sorted `entries`) is O(log n) per lookup
  /// instead of decoding and re-sorting every key on each call. Built lazily
  /// and maintained incrementally on put/remove/clear.
  SplayTreeMap<Key, bool>? _sortedKeys;

  BoxMap(this._mapName, this._lazyBox, this._store, this._keyCodec,
      this._keyComparator);

  SplayTreeMap<Key, bool> _keyIndex() {
    var index = _sortedKeys;
    if (index == null) {
      index = SplayTreeMap<Key, bool>(_keyComparator);
      for (var encoded in _lazyBox.keys) {
        index[_unWrapKey(encoded) as Key] = true;
      }
      _sortedKeys = index;
    }
    return index;
  }

  @override
  Future<Value?> operator [](Key key) async {
    var val = await _lazyBox.get(_wrapKey(key), defaultValue: null);
    return val as Value?;
  }

  @override
  Future<Key?> ceilingKey(Key key) async {
    return _keyIndex().ceilingKey(key) as Key?;
  }

  @override
  Future<void> clear() async {
    await _lazyBox.clear();
    _sortedKeys?.clear();
    await updateLastModifiedTime();
  }

  @override
  Future<void> close() async {
    if (!_closed && !_dropped) {
      await _store.closeMap(_mapName);
      _closed = true;
    }
  }

  @override
  Future<bool> containsKey(Key key) async {
    return _lazyBox.containsKey(_wrapKey(key));
  }

  @override
  Future<void> drop() async {
    if (!_dropped) {
      _dropped = true;
      _closed = true;
      await _store.closeMap(_mapName);
      await _store.removeMap(_mapName);
    }
  }

  @override
  Stream<(Key, Value)> entries() async* {
    // iterate in sorted key order so ordered/grouped index scans are correct
    for (var key in _keyIndex().keys.toList()) {
      var val = await _lazyBox.get(_wrapKey(key));
      yield (key, val);
    }
  }

  @override
  Future<Key?> floorKey(Key key) async {
    return _keyIndex().floorKey(key) as Key?;
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() =>
      _store as NitriteStore<Config>;

  @override
  Future<Key?> higherKey(Key key) async {
    return _keyIndex().higherKey(key) as Key?;
  }

  @override
  Future<void> initialize() async {}

  @override
  bool get isClosed => _closed;

  @override
  bool get isDropped => _dropped;

  @override
  Future<bool> isEmpty() async {
    return _lazyBox.isEmpty;
  }

  @override
  Stream<Key> keys() async* {
    for (var key in _lazyBox.keys) {
      yield _unWrapKey(key) as Key;
    }
  }

  @override
  Future<Key?> lowerKey(Key key) async {
    return _keyIndex().lowerKey(key) as Key?;
  }

  @override
  String get name => _mapName;

  @override
  Future<void> put(Key key, Value value) async {
    try {
      await _lazyBox.put(_wrapKey(key), value);
      _sortedKeys?[key] = true;
      await updateLastModifiedTime();
    } catch (e, s) {
      throw NitriteException('Failed to put $key: $value pair in $_mapName',
          cause: e, stackTrace: s);
    }
  }

  @override
  Future<Value?> putIfAbsent(Key key, Value value) async {
    var val = await _lazyBox.get(_wrapKey(key));
    if (val == null) {
      await put(key, value);
      return null;
    }
    return val;
  }

  @override
  Future<Value?> remove(Key key) async {
    var wrappedKey = _wrapKey(key);
    if (!_lazyBox.containsKey(wrappedKey)) {
      return null;
    }

    var val = await _lazyBox.get(wrappedKey);
    await _lazyBox.delete(wrappedKey);
    _sortedKeys?.remove(key);
    await updateLastModifiedTime();
    return val;
  }

  @override
  Stream<(Key, Value)> reversedEntries() async* {
    // iterate in descending sorted key order
    for (var key in _keyIndex().keys.toList().reversed) {
      var val = await _lazyBox.get(_wrapKey(key));
      yield (key, val);
    }
  }

  @override
  Future<int> size() async {
    return _lazyBox.length;
  }

  @override
  Stream<Value> values() async* {
    for (var key in _lazyBox.keys) {
      var value = await _lazyBox.get(key) as Value;
      yield value;
    }
  }

  @override
  Future<Key?> firstKey() async {
    var index = _keyIndex();
    return index.isEmpty ? null : index.firstKey();
  }

  @override
  Future<Key?> lastKey() async {
    var index = _keyIndex();
    return index.isEmpty ? null : index.lastKey();
  }

  // Keys need to be Strings or integers
  dynamic _wrapKey(Key key) {
    return _keyCodec.encode(key);
  }

  // Keys need to be Strings or integers
  dynamic _unWrapKey(dynamic key) {
    return _keyCodec.decode(key);
  }
}
