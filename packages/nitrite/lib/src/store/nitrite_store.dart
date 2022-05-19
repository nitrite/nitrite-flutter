import 'package:nitrite/nitrite.dart';

abstract class NitriteStore<Config extends StoreConfig> extends NitritePlugin {
  void openOrCreate();

  bool get isClosed;

  Set<String> get collectionNames;

  Set<String> get repositoryRegistry;

  Map<String, Set<String>> get keyedRepositoryRegistry;

  bool get hasUnsavedChanges;

  bool get isReadOnly;

  void commit();

  void beforeClose();

  bool hasMap(String mapName);

  NitriteMap<Key, Value> openMap<Key, Value>(String mapName);

  void closeMap(String mapName);

  void removeMap(String mapName);

  NitriteRTree<Key, Value> openRTree<Key extends BoundingBox, Value>(
      String rTreeName);

  void closeRTree(String rTreeName);

  void removeRTree(String rTreeName);

  void subscribe(StoreEventListener listener);

  void unsubscribe(StoreEventListener listener);

  String get storeVersion;

  Config get storeConfig;

  StoreCatalog get catalog;
}
