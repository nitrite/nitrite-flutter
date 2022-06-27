import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/splay_tree_extensions.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

class InMemoryMap<Key, Value> extends NitriteMap<Key, Value> {
  final SplayTreeMap<Key, Value> _backingMap;
  final NitriteStore _nitriteStore;
  final String _mapName;

  bool _droppedFlag = false;
  bool _closedFlag = false;

  InMemoryMap(this._mapName, this._nitriteStore)
      : _backingMap = SplayTreeMap<Key, Value>(_comp);

  @override
  String get name => _mapName;

  @override
  Future<bool> containsKey(Key key) async {
    _checkOpened();
    return _backingMap.containsKey(key);
  }

  @override
  Future<Value?> operator [](Key key) async {
    _checkOpened();
    return _backingMap[key];
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    return _nitriteStore as NitriteStore<Config>;
  }

  @override
  Future<void> clear() {
    _checkOpened();
    _backingMap.clear();
    return updateLastModifiedTime();
  }

  @override
  Stream<Value> values() {
    _checkOpened();
    return Stream.fromIterable(_backingMap.values);
  }

  @override
  Future<Value?> remove(Key key) async {
    _checkOpened();
    return _backingMap.remove(key);
  }

  @override
  Stream<Key> keys() {
    _checkOpened();
    return Stream.fromIterable(_backingMap.keys);
  }

  @override
  Future<void> put(Key key, Value value) {
    _checkOpened();
    value.notNullOrEmpty("value cannot be null");
    _backingMap[key] = value;
    return updateLastModifiedTime();
  }

  @override
  Future<int> size() async {
    _checkOpened();
    return _backingMap.length;
  }

  @override
  Future<Value?> putIfAbsent(Key key, Value value) async {
    _checkOpened();
    value.notNullOrEmpty("value cannot be null");
    return _backingMap.putIfAbsent(key, () => value);
  }

  @override
  Stream<Pair<Key, Value>> entries() {
    _checkOpened();
    return Stream.fromIterable(
        _backingMap.entries.map((e) => Pair(e.key, e.value)));
  }

  @override
  Stream<Pair<Key, Value>> reversedEntries() {
    _checkOpened();
    return Stream.fromIterable(
        _backingMap.reversedEntries.map((e) => Pair(e.key, e.value)));
  }

  @override
  Future<Key?> higherKey(Key key) async {
    _checkOpened();
    if (key == null) return null;
    return _backingMap.higherKey(key);
  }

  @override
  Future<Key?> ceilingKey(Key key) async {
    _checkOpened();
    if (key == null) return null;
    return _backingMap.ceilingKey(key);
  }

  @override
  Future<Key?> lowerKey(Key key) async {
    _checkOpened();
    if (key == null) return null;
    return _backingMap.lowerKey(key);
  }

  @override
  Future<Key?> floorKey(Key key) async {
    _checkOpened();
    if (key == null) return null;
    return _backingMap.floorKey(key);
  }

  @override
  Future<bool> isEmpty() async {
    _checkOpened();
    return _backingMap.isEmpty;
  }

  @override
  Future<void> drop() async {
    _checkOpened();
    _droppedFlag = true;
    await clear();
    await getStore().removeMap(_mapName);
  }

  @override
  Future<void> close() async {
    _closedFlag = true;
  }

  static int _comp(k1, k2) {
    if (k1 is Comparable && k2 is Comparable) {
      return compare(k1, k2);
    }
    return Comparable.compare(k1, k2);
  }

  void _checkOpened() {
    if (_closedFlag) {
      throw NitriteException('Map $_mapName is closed');
    }
    if (_droppedFlag) {
      throw NitriteException('Map $_mapName is dropped');
    }
  }
}
