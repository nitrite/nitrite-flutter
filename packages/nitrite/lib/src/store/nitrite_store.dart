import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/store/nitrite_map.dart';

abstract class NitriteStore<Config extends StoreConfig> extends NitritePlugin {
  Future<void> openOrCreate();

  bool get isClosed;

  Future<Set<String>> get collectionNames;

  Future<Set<String>> get repositoryRegistry;

  Future<Map<String, Set<String>>> get keyedRepositoryRegistry;

  bool get hasUnsavedChanges;

  bool get isReadOnly;

  Future<void> commit();

  Future<void> beforeClose();

  Future<bool> hasMap(String mapName);

  Future<NitriteMap<Key, Value>> openMap<Key, Value>(String mapName);

  Future<void> closeMap(String mapName);

  Future<void> removeMap(String mapName);

  Future<NitriteRTree<Key, Value>> openRTree<Key extends BoundingBox, Value>(
      String rTreeName);

  Future<void> closeRTree(String rTreeName);

  Future<void> removeRTree(String rTreeName);

  void subscribe(StoreEventListener listener);

  void unsubscribe(StoreEventListener listener);

  String get storeVersion;

  Config get storeConfig;

  StoreCatalog get catalog;
}
