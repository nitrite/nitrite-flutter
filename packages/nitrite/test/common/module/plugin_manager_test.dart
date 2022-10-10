import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/mapper/simple_document_mapper.dart';
import 'package:nitrite/src/common/module/plugin_manager.dart';
import 'package:nitrite/src/store/memory/in_memory_store.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'plugin_manager_test.mocks.dart';

@GenerateMocks([NitriteModule, NitritePlugin])
void main() {
  group("Plugin Manager Test Suite", () {
    test("Test LoadModule", () async {
      var pluginManager = PluginManager(NitriteConfig());
      var nitriteModule = MockNitriteModule();
      when(nitriteModule.plugins).thenReturn(<NitritePlugin>{});
      await pluginManager.loadModule(nitriteModule);
      verify(nitriteModule.plugins).called(1);
    });

    test("Test LoadModule with Exception", () async {
      var pluginManager = PluginManager(NitriteConfig());
      var nitritePluginSet = {MockNitritePlugin()};
      var nitriteModule = MockNitriteModule();
      when(nitriteModule.plugins).thenReturn(nitritePluginSet);
      expect(() async => await pluginManager.loadModule(nitriteModule),
          throwsPluginException);
      verify(nitriteModule.plugins).called(2);
    });

    test("Test FindAndLoadPlugins", () async {
      var pluginManager = PluginManager(NitriteConfig());
      await pluginManager.findAndLoadPlugins();

      var nitriteStore = pluginManager.getNitriteStore();
      expect(nitriteStore, TypeMatcher<InMemoryStore>());
      expect(pluginManager.indexerMap.length, 3);
      expect(pluginManager.nitriteMapper, TypeMatcher<SimpleDocumentMapper>());
      expect(nitriteStore.isClosed, isFalse);
    });
  });
}
