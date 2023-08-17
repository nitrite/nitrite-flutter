import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/splay_tree_extensions.dart';
import 'package:nitrite/src/store/memory/in_memory_map.dart';
import 'package:rxdart/rxdart.dart';

class TransactionalMap<K, V> extends NitriteMap<K, V> {
  final NitriteMap<K, V> _primaryMap;
  final NitriteMap<K, V> _backingMap;
  final String _mapName;
  final NitriteStore _store;
  final Set<K> _tombstones;

  bool _droppedFlag = false;
  bool _closedFlag = false;
  bool _cleared = false;

  TransactionalMap(this._mapName, NitriteMap<K, V>? primaryMap, this._store)
      : _primaryMap = primaryMap ?? InMemoryMap<K, V>(_mapName, _store),
        _backingMap = InMemoryMap<K, V>(_mapName, _store),
        _tombstones = <K>{};

  @override
  String get name => _mapName;

  @override
  bool get isClosed {
    if (_primaryMap.isClosed || _primaryMap.isDropped) return true;
    return _closedFlag;
  }

  @override
  bool get isDropped => _droppedFlag;

  @override
  Future<bool> containsKey(K key) async {
    if (_cleared) return false;

    if (await _backingMap.containsKey(key)) {
      return true;
    }

    if (_tombstones.contains(key)) {
      return false;
    }

    return await _primaryMap.containsKey(key);
  }

  @override
  Future<V?> operator [](K key) async {
    if (_tombstones.contains(key) || _cleared) {
      return null;
    }

    var result = await _backingMap[key];
    if (result == null) {
      result = await _primaryMap[key];

      if (result is List) {
        var list = [...result];
        await _backingMap.put(key, list as V);
        result = list as V;
      }
    }

    return result;
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    return _store as NitriteStore<Config>;
  }

  @override
  Future<void> clear() async {
    await _backingMap.clear();
    _cleared = true;
    await _store.closeMap(_mapName);
  }

  @override
  Stream<V> values() async* {
    if (_cleared) Stream.empty();

    await for (var entry in entries()) {
      yield entry.$2;
    }
  }

  @override
  Future<V?> remove(K key) async {
    V? item;
    if (_cleared || _tombstones.contains(key)) return null;

    if (await _backingMap.containsKey(key)) {
      item = await _backingMap.remove(key);
    } else if (await _primaryMap.containsKey(key)) {
      item = await _primaryMap[key];
    }
    _tombstones.add(key);
    return item;
  }

  @override
  Stream<K> keys() {
    if (_cleared) return Stream.empty();

    return ConcatStream([
      _primaryMap.keys().where((key) => !_tombstones.contains(key)),
      _backingMap.keys(),
    ]);
  }

  @override
  Future<void> put(K key, V value) {
    _cleared = false;
    _tombstones.remove(key);
    return _backingMap.put(key, value);
  }

  @override
  Future<int> size() async {
    if (_cleared) return 0;
    return _backingMap.size();
  }

  @override
  Future<V?> putIfAbsent(K key, V value) async {
    _cleared = false;
    var v = await this[key];
    if (v == null) {
      await put(key, value);
    }
    return v;
  }

  @override
  Stream<(K, V)> entries() {
    if (_cleared) return Stream.empty();

    return ConcatStream([
      _primaryMap.entries().where((entry) => !_tombstones.contains(entry.$1)),
      _backingMap.entries(),
    ]);
  }

  @override
  Stream<(K, V)> reversedEntries() {
    if (_cleared) return Stream.empty();

    return ConcatStream([
      _primaryMap
          .reversedEntries()
          .where((entry) => !_tombstones.contains(entry.$1)),
      _backingMap.reversedEntries(),
    ]);
  }

  @override
  Future<K?> higherKey(K key) async {
    if (_cleared) return null;

    var primaryKey = await _primaryMap.higherKey(key);
    var backingKey = await _backingMap.higherKey(key);

    if (primaryKey == null) return backingKey;
    if (backingKey == null) return primaryKey;

    var keyMap = SplayTreeMap<K, K>();
    keyMap[backingKey] = backingKey;
    keyMap[primaryKey] = primaryKey;

    return keyMap.higherKey(key);
  }

  @override
  Future<K?> ceilingKey(K key) async {
    if (_cleared) return null;

    var primaryKey = await _primaryMap.ceilingKey(key);
    var backingKey = await _backingMap.ceilingKey(key);

    if (primaryKey == null) return backingKey;
    if (backingKey == null) return primaryKey;

    var keyMap = SplayTreeMap<K, K>();
    keyMap[backingKey] = backingKey;
    keyMap[primaryKey] = primaryKey;

    return keyMap.ceilingKey(key);
  }

  @override
  Future<K?> lowerKey(K key) async {
    if (_cleared) return null;

    var primaryKey = await _primaryMap.lowerKey(key);
    var backingKey = await _backingMap.lowerKey(key);

    if (primaryKey == null) return backingKey;
    if (backingKey == null) return primaryKey;

    var keyMap = SplayTreeMap<K, K>();
    keyMap[backingKey] = backingKey;
    keyMap[primaryKey] = primaryKey;

    return keyMap.lowerKey(key);
  }

  @override
  Future<K?> floorKey(K key) async {
    if (_cleared) return null;

    var primaryKey = await _primaryMap.floorKey(key);
    var backingKey = await _backingMap.floorKey(key);

    if (primaryKey == null) return backingKey;
    if (backingKey == null) return primaryKey;

    var keyMap = SplayTreeMap<K, K>();
    keyMap[backingKey] = backingKey;
    keyMap[primaryKey] = primaryKey;

    return keyMap.floorKey(key);
  }

  @override
  Future<bool> isEmpty() async {
    if (_cleared) return true;

    var result = await _primaryMap.isEmpty();
    if (result) {
      return _backingMap.isEmpty();
    }
    return false;
  }

  @override
  Future<void> drop() async {
    if (!_droppedFlag) {
      await _backingMap.clear();
      _tombstones.clear();
      await _primaryMap.drop();
      _cleared = true;
      _droppedFlag = true;
      await _store.removeMap(_mapName);
    }
  }

  @override
  Future<void> close() async {
    await _backingMap.clear();
    _tombstones.clear();
    _cleared = true;
    _closedFlag = true;
    await _store.closeMap(_mapName);
  }

  @override
  Future<void> initialize() async {}
}
