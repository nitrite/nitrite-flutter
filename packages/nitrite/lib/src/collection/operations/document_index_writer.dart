import 'dart:async';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/index_operations.dart';
import 'package:nitrite/src/common/util/document_utils.dart';
import 'package:nitrite/src/common/util/object_utils.dart';

/// @nodoc
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

  Future<void> updateIndexEntry(
    Document oldDoc,
    Document newDoc,
    Document updatedFields,
  ) async {
    var indexEntries = await _indexOperations.listIndexes();
    // filter out the index which is not affected by the update
    for (var indexDescriptor in indexEntries) {
      var fields = indexDescriptor.fields;

      // if the index is affected by the update
      if (fields.fieldNames.any((field) => updatedFields.containsKey(field))) {
        // "affected" only means the update carries the field. An update that
        // writes the whole document back, the common upsert shape, carries every
        // indexed field with its old value, and rewriting those entries is pure
        // cost. A dirty index still has to be rebuilt, so that case is not
        // skipped.
        if (!await _indexOperations.shouldRebuildIndex(fields) &&
            _sameIndexedValues(oldDoc, newDoc, fields)) {
          continue;
        }

        var indexType = indexDescriptor.indexType;
        var nitriteIndexer = await _nitriteConfig.findIndexer(indexType);

        await _removeIndexEntryInternal(
          indexDescriptor,
          oldDoc,
          nitriteIndexer,
        );
        await _writeIndexEntryInternal(indexDescriptor, newDoc, nitriteIndexer);
      }
    }
  }

  Future<void> removeIndexEntry(Document document) async {
    var indexEntries = await _indexOperations.listIndexes();
    for (var indexDescriptor in indexEntries) {
      var indexType = indexDescriptor.indexType;
      var nitriteIndexer = await _nitriteConfig.findIndexer(indexType);

      await _removeIndexEntryInternal(
        indexDescriptor,
        document,
        nitriteIndexer,
      );
    }
  }

  /// Whether the two documents hold the same values for every field of the
  /// index, compared deeply so that lists and embedded values count as equal
  /// when their contents are.
  bool _sameIndexedValues(Document oldDoc, Document newDoc, Fields fields) {
    var before = getDocumentValues(oldDoc, fields).values;
    var after = getDocumentValues(newDoc, fields).values;
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (before[i].$1 != after[i].$1) return false;
      if (!deepEquals(before[i].$2, after[i].$2)) return false;
    }
    return true;
  }

  Future<void> _writeIndexEntryInternal(
    IndexDescriptor indexDescriptor,
    Document document,
    NitriteIndexer nitriteIndexer,
  ) async {
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
        fieldValues,
        indexDescriptor,
        _nitriteConfig,
      );
    }
  }

  Future<void> _removeIndexEntryInternal(
    IndexDescriptor indexDescriptor,
    Document document,
    NitriteIndexer nitriteIndexer,
  ) async {
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
        fieldValues,
        indexDescriptor,
        _nitriteConfig,
      );
    }
  }
}
