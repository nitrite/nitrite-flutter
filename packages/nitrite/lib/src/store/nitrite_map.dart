import 'package:nitrite/src/common/constants.dart';
import 'package:nitrite/src/common/meta/attributes.dart';
import 'package:nitrite/src/common/meta/attributes_aware.dart';
import 'package:nitrite/src/store/nitrite_store.dart';
import 'package:nitrite/src/store/store_config.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

abstract class NitriteMap<Key, Value> extends AttributesAware {
  Future<bool> containsKey(Key key);

  Future<Value?> operator [](Key key);

  Future<void> clear();

  Future<void> close();

  Stream<Value> values();

  Stream<Key> keys();

  Future<Value?> remove(Key key);

  Future<void> put(Key key, Value value);

  Future<int> size();

  Future<Value?> putIfAbsent(Key key, Value value);

  Future<Key?> higherKey(Key key);

  Future<Key?> ceilingKey(Key key);

  Future<Key?> lowerKey(Key key);

  Future<Key?> floorKey(Key key);

  bool isEmpty();

  NitriteStore<Config> getStore<Config extends StoreConfig>();

  String get name;

  RecordStream<Pair<Key, Value>> entries();

  RecordStream<Pair<Key, Value>> reversedEntries();

  Future<void> drop();

  @override
  Future<Attributes> getAttributes() async {
    NitriteMap<String, Attributes> metaMap =
        await getStore().openMap(Constants.metaMapName);

    if (!identical(name, Constants.metaMapName)) {
      var attributes = await metaMap[name];
      if (attributes != null) {
        return attributes;
      } else {
        return Attributes();
      }
    }
    return Attributes();
  }

  @override
  Future<void> setAttributes(Attributes attributes) async {
    var metaMap =
        await getStore().openMap<String, Attributes>(Constants.metaMapName);

    if (!identical(name, Constants.metaMapName)) {
      await metaMap.put(name, attributes);
    }
    return;
  }

  Future<void> updateLastModifiedTime() async {
    if (name.isNullOrEmpty || identical(name, Constants.metaMapName)) {
      return;
    }

    var metaMap =
        await getStore().openMap<String, Attributes>(Constants.metaMapName);

    var attributes = await metaMap[name];
    if (attributes == null) {
      attributes = Attributes(name);
      metaMap.put(name, attributes);
    }
    
    attributes.set(Attributes.lastModifiedTime,
        DateTime.now().millisecondsSinceEpoch.toString());
  }
}
