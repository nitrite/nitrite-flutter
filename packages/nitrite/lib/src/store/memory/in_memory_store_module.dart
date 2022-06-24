import 'package:nitrite/src/common/module/nitrite_module.dart';
import 'package:nitrite/src/store/nitrite_store.dart';
import 'package:nitrite/src/store/store_config.dart';
import 'package:nitrite/src/store/store_module.dart';

class InMemoryStoreModule extends StoreModule {
  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    // TODO: implement getStore
    throw UnimplementedError();
  }

  @override
  // TODO: implement plugins
  Set<NitritePlugin> get plugins => throw UnimplementedError();

}
