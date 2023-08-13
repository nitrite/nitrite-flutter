import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/index_operations.dart';
import 'package:nitrite/src/collection/operations/read_operations.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:nitrite/src/store/memory/in_memory_map.dart';
import 'package:nitrite/src/store/memory/in_memory_store.dart';
import 'package:nitrite/src/store/memory/in_memory_store_module.dart';
import 'package:test/test.dart';

import 'read_operation_test.mocks.dart';

@GenerateMocks([IndexOperations, Filter])
main() {
  group(retry: 3, 'Read Operation Test Suite', () {
    setUp(() {
      // Additional setup goes here.
    });
  });

  test("Test Find", () async {
    var indexOperations = MockIndexOperations();
    when(indexOperations.listIndexes()).thenAnswer((_) => Future.value([]));
    var nitriteConfig = NitriteConfig();
    var nitriteMap = InMemoryMap<NitriteId, Document>(
        "Map Name", InMemoryStore(InMemoryConfig()));

    var readOperation = ReadOperations("Collection Name", indexOperations,
        nitriteConfig, nitriteMap, ProcessorChain());

    var filter = MockFilter();
    var cursor = readOperation.find(filter, FindOptions());
    var list = await cursor.toList();
    expect(list, isEmpty);
    verify(indexOperations.listIndexes()).called(1);
  });

  test("Test Find with IndexDescriptor", () async {
    var indexOperations = MockIndexOperations();
    var indexDescriptor = IndexDescriptor(
        IndexType.unique, Fields.withNames(["a"]), "Collection Name");
    when(indexOperations.listIndexes())
        .thenAnswer((_) => Future.value([indexDescriptor]));

    var nitriteConfig = NitriteConfig();
    var nitriteMap = InMemoryMap<NitriteId, Document>(
        "Map Name", InMemoryStore(InMemoryConfig()));

    var readOperation = ReadOperations("Collection Name", indexOperations,
        nitriteConfig, nitriteMap, ProcessorChain());

    var filter = MockFilter();
    var cursor = readOperation.find(filter, FindOptions());
    var list = await cursor.toList();
    expect(list, isEmpty);
    verify(indexOperations.listIndexes()).called(1);
  });

  test("Test GetById", () async {
    var indexOperations = MockIndexOperations();
    when(indexOperations.listIndexes()).thenAnswer((_) => Future.value([]));
    var nitriteConfig = NitriteConfig();
    var nitriteMap = InMemoryMap<NitriteId, Document>(
        "Map Name", InMemoryStore(InMemoryConfig()));

    var readOperation = ReadOperations("Collection Name", indexOperations,
        nitriteConfig, nitriteMap, ProcessorChain());

    var byId = await readOperation.getById(NitriteId.newId());
    expect(byId, isNull);
    verifyNever(indexOperations.listIndexes());
  });
}
