import 'package:event_bus/event_bus.dart';
import 'package:nitrite/src/collection/document.dart';
import 'package:nitrite/src/collection/nitrite_id.dart';
import 'package:nitrite/src/collection/operations/document_index_writer.dart';
import 'package:nitrite/src/collection/operations/read_operations.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:nitrite/src/store/nitrite_map.dart';

class WriteOperations {
  WriteOperations(
      DocumentIndexWriter indexWriter,
      ReadOperations readOperations,
      NitriteMap<NitriteId, Document> nitriteMap,
      EventBus eventBus,
      ProcessorChain processorChain);
}
