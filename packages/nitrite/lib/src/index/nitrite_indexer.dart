import 'package:nitrite/nitrite.dart';

abstract class NitriteIndexer extends NitritePlugin {
  Stream<NitriteId> findByFilter(
      FindPlan findPlan, NitriteConfig nitriteConfig) {
    throw UnimplementedError();
  }

  Future<void> validateIndex(Fields fields) {
    throw UnimplementedError();
  }

  dropIndex(indexDescriptor, NitriteConfig nitriteConfig) {}

  writeIndexEntry(fieldValues, IndexDescriptor indexDescriptor,
      NitriteConfig nitriteConfig) {}

  Future<void> removeIndexEntry(FieldValues fieldValues,
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig) async {}
}
