import 'package:nitrite/nitrite.dart';

class PluginManager {
  void loadModule(NitriteModule module) {}

  void findAndLoadPlugins() {}

  Map<String, NitriteIndexer> getIndexerMap() { return {}; }

  NitriteMapper get mapper {
    throw UnimplementedError();
  }

  NitriteStore<Config> getNitriteStore<Config extends StoreConfig>() {
    throw UnimplementedError();
  }

  void close() {}

  void initializePlugins() {}

}
