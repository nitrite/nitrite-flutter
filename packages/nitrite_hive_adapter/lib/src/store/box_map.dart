import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/src/store/hive_store.dart';
import 'package:nitrite_hive_adapter/src/store/key_encoder.dart';

class BoxMap<Key, Value> extends NitriteMap<Key, Value> {
  final String _mapName;
  final LazyBox _lazyBox;
  final HiveStore _store;
  final KeyComparator _keyComparator;
  final KeyCodec _keyCodec;
  bool _dropped = false;
  bool _closed = false;

  BoxMap(this._mapName, this._lazyBox, this._store, this._keyCodec,
      this._keyComparator);

  @override
  Future<Value?> operator [](Key key) async {
    var val = await _lazyBox.get(_wrapKey(key), defaultValue: null);
    return val as Value?;
  }

  @override
  Future<Key?> ceilingKey(Key key) async {
    var keys = _sortedKeys();
    for (var item in keys) {
      var result = _keyComparator(item, key);
      if (result >= 0) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> clear() async {
    await _lazyBox.clear();
    await updateLastModifiedTime();
  }

  @override
  Future<void> close() async {
    if (!_closed && !_dropped) {
      await _lazyBox.close();
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
  Stream<Pair<Key, Value>> entries() async* {
    for (var key in _lazyBox.keys) {
      var val = await _lazyBox.get(key);
      yield Pair(_unWrapKey(key), val);
    }
  }

  @override
  Future<Key?> floorKey(Key key) async {
    var keys = _sortedKeys().reversed;
    for (var item in keys) {
      var result = _keyComparator(item, key);
      if (result <= 0) {
        return item;
      }
    }
    return null;
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() =>
      _store as NitriteStore<Config>;

  @override
  Future<Key?> higherKey(Key key) async {
    var keys = _sortedKeys();
    for (var item in keys) {
      var result = _keyComparator(item, key);
      if (result > 0) {
        return item;
      }
    }
    return null;
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
    var keys = _sortedKeys().reversed;
    for (var item in keys) {
      var result = _keyComparator(item, key);
      if (result < 0) {
        return item;
      }
    }
    return null;
  }

  @override
  String get name => _mapName;

  @override
  Future<void> put(Key key, Value value) async {
    try {
      await _lazyBox.put(_wrapKey(key), value);
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
    await updateLastModifiedTime();
    return val;
  }

  @override
  Stream<Pair<Key, Value>> reversedEntries() async* {
    var reversedKeys = _lazyBox.keys.toList().reversed;
    for (var key in reversedKeys) {
      var val = await _lazyBox.get(key);
      yield Pair(_unWrapKey(key), val);
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

  // Keys need to be Strings or integers
  dynamic _wrapKey(Key key) {
    return _keyCodec.encode(key);
  }

  // Keys need to be Strings or integers
  dynamic _unWrapKey(dynamic key) {
    return _keyCodec.decode(key);
  }

  List<Key> _sortedKeys() {
    var list = _lazyBox.keys.map((e) => _unWrapKey(e) as Key).toList();
    list.sort(_keyComparator);
    return list;
  }
}
