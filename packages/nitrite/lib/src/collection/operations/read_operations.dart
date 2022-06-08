import 'package:event_bus/event_bus.dart';
import 'package:nitrite/src/collection/document.dart';
import 'package:nitrite/src/collection/nitrite_id.dart';
import 'package:nitrite/src/nitrite_config.dart';
import 'package:nitrite/src/store/nitrite_map.dart';

class ReadOperations {
  ReadOperations(
      String collectionName,
      NitriteMap<NitriteId, Document> nitriteMap,
      NitriteConfig nitriteConfig,
      EventBus eventBus);
}
