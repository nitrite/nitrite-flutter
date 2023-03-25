import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/document_index_writer.dart';
import 'package:nitrite/src/collection/operations/index_operations.dart';
import 'package:nitrite/src/index/comparable_indexer.dart';
import 'package:nitrite/src/store/memory/in_memory_store.dart';
import 'package:nitrite/src/store/memory/in_memory_store_module.dart';
import 'package:test/test.dart';

import 'doc_index_write_test.mocks.dart';

@GenerateMocks([IndexOperations, NitriteConfig])
void main() {
  group('Document Index Write Test Suite', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Test Write Index Entry', () async {
      var indexDescriptorList = <IndexDescriptor>[];
      indexDescriptorList.add(IndexDescriptor(
          IndexType.unique, Fields.withNames(["a"]), "Collection Name"));

      var indexOperations = MockIndexOperations();
      when(indexOperations.listIndexes())
          .thenAnswer((_) => Future.value(indexDescriptorList));
      when(indexOperations.shouldRebuildIndex(any))
          .thenAnswer((_) => Future.value(false));

      var config = MockNitriteConfig();
      when(config.findIndexer(IndexType.unique))
          .thenAnswer((_) => Future.value(UniqueIndexer()));
      when(config.getNitriteStore())
          .thenReturn(InMemoryStore(InMemoryConfig()));

      var indexWriter = DocumentIndexWriter(config, indexOperations);
      await indexWriter.writeIndexEntry(createDocument("a", 1));
      verify(indexOperations.listIndexes()).called(1);
    });

    test('Test Remove Index Entry', () async {
      var indexDescriptorList = <IndexDescriptor>[];
      indexDescriptorList.add(IndexDescriptor(
          IndexType.unique, Fields.withNames(["a"]), "Collection Name"));

      var indexOperations = MockIndexOperations();
      when(indexOperations.listIndexes())
          .thenAnswer((_) => Future.value(indexDescriptorList));
      when(indexOperations.shouldRebuildIndex(any))
          .thenAnswer((_) => Future.value(false));

      var config = MockNitriteConfig();
      when(config.findIndexer(IndexType.unique))
          .thenAnswer((_) => Future.value(UniqueIndexer()));
      when(config.getNitriteStore())
          .thenReturn(InMemoryStore(InMemoryConfig()));

      var indexWriter = DocumentIndexWriter(config, indexOperations);
      await indexWriter.removeIndexEntry(createDocument("a", 1));
      verify(indexOperations.listIndexes()).called(1);
    });

    test('Test Update Index Entry', () async {
      var indexDescriptorList = <IndexDescriptor>[];
      indexDescriptorList.add(IndexDescriptor(
          IndexType.unique, Fields.withNames(["a"]), "Collection Name"));

      var indexOperations = MockIndexOperations();
      when(indexOperations.listIndexes())
          .thenAnswer((_) => Future.value(indexDescriptorList));
      when(indexOperations.shouldRebuildIndex(any))
          .thenAnswer((_) => Future.value(false));

      var config = MockNitriteConfig();
      when(config.findIndexer(IndexType.unique))
          .thenAnswer((_) => Future.value(UniqueIndexer()));
      when(config.getNitriteStore()).thenReturn(InMemoryStore(InMemoryConfig()));

      var indexWriter = DocumentIndexWriter(config, indexOperations);
      await indexWriter.updateIndexEntry(
          createDocument("a", 1), createDocument("a", 2));
      verify(indexOperations.listIndexes()).called(1);
    });
  });
}
