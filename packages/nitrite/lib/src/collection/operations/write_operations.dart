import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/document_index_writer.dart';
import 'package:nitrite/src/collection/operations/read_operations.dart';
import 'package:nitrite/src/common/processors/processor.dart';

/// @nodoc
class WriteOperations {
  static final Logger _log = Logger('WriteOperations');
  final DocumentIndexWriter _documentIndexWriter;
  final ReadOperations _readOperations;
  final NitriteMap<NitriteId, Document> _nitriteMap;
  final EventBus _eventBus;
  final ProcessorChain _processorChain;

  WriteOperations(this._documentIndexWriter, this._readOperations,
      this._nitriteMap, this._eventBus, this._processorChain);

  Stream<NitriteId> insert(List<Document> documents) async* {
    _log.fine('Inserting ${documents.length} documents in ${_nitriteMap.name}');

    for (var document in documents) {
      var newDoc = document.clone();
      var nitriteId = newDoc.id;
      var source = newDoc.source;
      var time = DateTime.now().millisecondsSinceEpoch;

      if (replicator != newDoc.source) {
        // if replicator is not inserting the document that means
        // it is being inserted by user, so update metadata
        newDoc.remove(docSource);
        newDoc.put(docRevision, 1);
        newDoc.put(docModified, time);
      } else {
        // if replicator is inserting the document, remove the source
        // but keep the revision intact
        newDoc.remove(docSource);
      }

      // run processors
      var unprocessed = newDoc.clone();
      var processed = await _processorChain.processBeforeWrite(unprocessed);
      _log.fine('Processed document with id : $nitriteId');

      _log.fine('Inserting document with id : $nitriteId');
      var hasKey = await _nitriteMap.containsKey(nitriteId);

      if (hasKey) {
        throw UniqueConstraintException('Document with id : $nitriteId already'
            ' exists in ${_nitriteMap.name}');
      } else {
        try {
          await _nitriteMap.putIfAbsent(nitriteId, processed);
          await _documentIndexWriter.writeIndexEntry(processed);
        } catch (e) {
          if (e is UniqueConstraintException || e is IndexingException) {
            _log.severe(
                'Error while writing index entry for document with id'
                ' : $nitriteId in ${_nitriteMap.name}',
                e);
            await _nitriteMap.remove(nitriteId);
          }
          rethrow;
        }
      }

      yield nitriteId;

      var eventInfo = CollectionEventInfo(
        item: newDoc,
        timestamp: time,
        eventType: EventType.insert,
        originator: source,
      );

      _alert(eventInfo);
    }
  }

  Stream<NitriteId> removeDocument(Document document) async* {
    var nitriteId = document.id;
    var removed = await _nitriteMap.remove(nitriteId);
    if (removed != null) {
      var removedAt = DateTime.now().millisecondsSinceEpoch;
      await _documentIndexWriter.removeIndexEntry(removed);

      var rev = removed.get(docRevision);
      removed.put(docRevision, rev + 1);
      removed.put(docModified, removedAt);

      _log.fine(
          'Removed document with id : $nitriteId from ${_nitriteMap.name}');

      yield nitriteId;

      var eventInfo = CollectionEventInfo(
        item: removed,
        timestamp: removedAt,
        eventType: EventType.remove,
        originator: document.source,
      );
      _alert(eventInfo);
    }
  }

  Stream<NitriteId> removeByFilter(Filter filter, bool once) async* {
    var cursor = _readOperations.find(filter, null);

    var count = 0;
    var nitriteIds = <NitriteId, String>{};
    await for (var document in cursor) {
      count++;

      var unprocessed = document.clone();
      var processed = await _processorChain.processAfterRead(unprocessed);
      _log.fine('Processed document with id : ${processed.id}');

      nitriteIds[document.id] = document.source;

      if (once) {
        break;
      }
    }

    for (var entry in nitriteIds.entries) {
      var nitriteId = entry.key;
      var removed = await _nitriteMap.remove(nitriteId);
      if (removed != null) {
        var removedAt = DateTime.now().millisecondsSinceEpoch;
        await _documentIndexWriter.removeIndexEntry(removed);

        var rev = removed.get(docRevision);
        removed.put(docRevision, rev + 1);
        removed.put(docModified, removedAt);

        _log.fine(
            'Removed document with id : $nitriteId from ${_nitriteMap.name}');

        yield nitriteId;

        var eventInfo = CollectionEventInfo(
          item: removed,
          timestamp: removedAt,
          eventType: EventType.remove,
          originator: entry.value,
        );

        _alert(eventInfo);
      }
    }

    if (count == 0) {
      _log.fine('No documents found for filter : $filter');
      yield* Stream.empty();
    } else {
      _log.fine('Removed $count documents for filter : $filter');
    }
  }

  Stream<NitriteId> update(
      Filter filter, Document update, UpdateOptions updateOptions) async* {
    var cursor = _readOperations.find(filter, null);
    var document = update.clone();
    document.remove(docId);
    var source = document.source;

    if (replicator != source) {
      document.remove(docRevision);
    }

    if (document.size != 0) {
      var count = 0;

      await for (var doc in cursor) {
        count++;

        if (count > 1 && updateOptions.justOnce) {
          break;
        }

        var newDoc = doc.clone();
        var oldDoc = doc.clone();
        var time = DateTime.now().millisecondsSinceEpoch;

        var nitriteId = newDoc.id;
        _log.fine('Updating document with id : $nitriteId '
            'in ${_nitriteMap.name}');

        if (replicator != source) {
          document.remove(docSource);
          newDoc.merge(document);
          var rev = newDoc.get(docRevision);
          newDoc.put(docRevision, rev + 1);
          newDoc.put(docModified, time);
        } else {
          document.remove(docSource);
          newDoc.merge(document);
        }

        // run processors
        var unprocessed = newDoc.clone();
        var processed = await _processorChain.processBeforeWrite(unprocessed);
        _log.fine('Processed document with id : $nitriteId');

        await _nitriteMap.put(nitriteId, processed);
        _log.fine('Updated document with id : $nitriteId '
            'in ${_nitriteMap.name}');

        try {
          await _documentIndexWriter.updateIndexEntry(oldDoc, processed);

          // if 'update' only contains id value, affected count = 0
          if (document.size > 0) {
            yield nitriteId;
          }
        } catch (e) {
          if (e is UniqueConstraintException || e is IndexingException) {
            _log.severe('Error while writing index entry for document with id'
                ' : $nitriteId in ${_nitriteMap.name}');
            await _nitriteMap.put(nitriteId, oldDoc);
            await _documentIndexWriter.updateIndexEntry(processed, oldDoc);
          }
          rethrow;
        }

        var eventInfo = CollectionEventInfo(
          item: newDoc,
          timestamp: time,
          eventType: EventType.update,
          originator: source,
        );
        _alert(eventInfo);
      }

      if (count == 0) {
        _log.fine('No documents found for update in ${_nitriteMap.name}');
        if (updateOptions.insertIfAbsent) {
          yield* insert([document]);
        }
      }

      _log.fine('Updated $count documents in ${_nitriteMap.name}');
    } else {
      _log.fine('No fields to update');
      yield* Stream.empty();
    }
  }

  void _alert<T>(CollectionEventInfo<T> changedItem) {
    _log.fine('Alerting event listeners for action : ${changedItem.eventType} '
        'in collection ${_nitriteMap.name}');

    if (!_eventBus.streamController.isClosed) {
      _eventBus.fire(changedItem);
    }
  }
}
