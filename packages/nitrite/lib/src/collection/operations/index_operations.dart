import 'package:event_bus/event_bus.dart';
import 'package:nitrite/src/collection/document.dart';
import 'package:nitrite/src/collection/nitrite_id.dart';
import 'package:nitrite/src/common/fields.dart';
import 'package:nitrite/src/nitrite_config.dart';
import 'package:nitrite/src/store/nitrite_map.dart';

class IndexOperations {
  IndexOperations(String collectionName, NitriteConfig nitriteConfig,
      NitriteMap<NitriteId, Document> nitriteMap, EventBus eventBus);

  close() {}

  createIndex(Fields indexFields, String indexType) {}

  dropAllIndices() {}
}
