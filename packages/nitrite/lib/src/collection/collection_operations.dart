import 'package:event_bus/event_bus.dart';
import 'package:nitrite/src/collection/document.dart';
import 'package:nitrite/src/collection/nitrite_id.dart';
import 'package:nitrite/src/common/fields.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:nitrite/src/nitrite_config.dart';
import 'package:nitrite/src/store/nitrite_map.dart';

class CollectionOperations {
  final String _collectionName;
  final NitriteMap<NitriteId, Document> _nitriteMap;
  final NitriteConfig _nitriteConfig;
  final EventBus _eventBus;

  CollectionOperations(this._collectionName, this._nitriteMap,
      this._nitriteConfig, this._eventBus);

  void addProcessor(Processor processor) {}

  Future<void> close() async {}

  Future<void> createIndex(Fields indexFields, String indexType) async {}
}
