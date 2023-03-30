import 'dart:async';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/index_operations.dart';
import 'package:nitrite/src/common/util/document_utils.dart';

class DocumentIndexWriter {
  final NitriteConfig _nitriteConfig;
  final IndexOperations _indexOperations;

  DocumentIndexWriter(this._nitriteConfig, this._indexOperations);

  Future<void> writeIndexEntry(Document document) async {
    var indexEntries = await _indexOperations.listIndexes();

    for (var indexDescriptor in indexEntries) {
      var indexType = indexDescriptor.indexType;

      var nitriteIndexer = await _nitriteConfig.findIndexer(indexType);
      await _writeIndexEntryInternal(indexDescriptor, document, nitriteIndexer);
    }
  }

  Future<void> updateIndexEntry(Document oldDoc, Document newDoc) async {
    var indexEntries = await _indexOperations.listIndexes();
    for (var indexDescriptor in indexEntries) {
      var indexType = indexDescriptor.indexType;
      var nitriteIndexer = await _nitriteConfig.findIndexer(indexType);

      await _removeIndexEntryInternal(
            indexDescriptor, oldDoc, nitriteIndexer);
        await _writeIndexEntryInternal(indexDescriptor, newDoc, nitriteIndexer);
    }
  }

  Future<void> removeIndexEntry(Document document) async {
    var indexEntries = await _indexOperations.listIndexes();
    for (var indexDescriptor in indexEntries) {
      var indexType = indexDescriptor.indexType;
      var nitriteIndexer = await _nitriteConfig.findIndexer(indexType);

        await _removeIndexEntryInternal(
            indexDescriptor, document, nitriteIndexer);
    }
  }

  Future<void> _writeIndexEntryInternal(IndexDescriptor indexDescriptor,
      Document document, NitriteIndexer nitriteIndexer) async {
    var fields = indexDescriptor.fields;
    var fieldValues = getDocumentValues(document, fields);

    // if dirty index and currently indexing is not running, rebuild
    var shouldRebuildIndex = await _indexOperations.shouldRebuildIndex(fields);
    if (shouldRebuildIndex) {
      // rebuild will also take care of the current document
      return _indexOperations.buildIndex(indexDescriptor, true);
    } else {
      // write to nitrite indexer
      return nitriteIndexer.writeIndexEntry(
          fieldValues, indexDescriptor, _nitriteConfig);
    }
  }

  Future<void> _removeIndexEntryInternal(IndexDescriptor indexDescriptor,
      Document document, NitriteIndexer nitriteIndexer) async {
    var fields = indexDescriptor.fields;
    var fieldValues = getDocumentValues(document, fields);

    // if dirty index and currently indexing is not running, rebuild
    var shouldRebuildIndex = await _indexOperations.shouldRebuildIndex(fields);
    if (shouldRebuildIndex) {
      // rebuild will also take care of the current document
      return _indexOperations.buildIndex(indexDescriptor, true);
    } else {
      // remove via nitrite indexer
      return nitriteIndexer.removeIndexEntry(
          fieldValues, indexDescriptor, _nitriteConfig);
    }
  }
}
