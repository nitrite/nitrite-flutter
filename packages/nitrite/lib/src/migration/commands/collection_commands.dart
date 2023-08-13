import 'package:event_bus/event_bus.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/collection_operations.dart';
import 'package:nitrite/src/collection/operations/index_manager.dart';
import 'package:nitrite/src/migration/commands/commands.dart';

class CollectionRenameCommand extends BaseCommand {
  final (String, String) _arguments;

  CollectionRenameCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var oldName = _arguments.$1;
    var newName = _arguments.$2;

    await initialize(nitrite, oldName);

    var newMap = await nitriteStore?.openMap<NitriteId, Document>(newName);
    var newOperations =
        CollectionOperations(newName, newMap!, nitrite.config, EventBus());

    try {
      await newOperations.initialize();

      await for (var pair in nitriteMap!.entries()) {
        await newMap.put(pair.$1, pair.$2);
      }

      var indexManager = IndexManager(oldName, nitrite.config);
      try {
        await indexManager.initialize();

        var indexEntries = await indexManager.getIndexDescriptors();
        for (var indexDescriptor in indexEntries) {
          var field = indexDescriptor.fields;
          var indexType = indexDescriptor.indexType;
          // create indexes in parallel
          await newOperations.createIndex(field, indexType);
        }

        await operations?.dropCollection();
      } finally {
        await indexManager.close();
      }
    } finally {
      await newOperations.close();
    }
  }
}

class AddFieldCommand extends BaseCommand {
  final Triplet<String, String, dynamic> _arguments;

  AddFieldCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var collectionName = _arguments.first;
    var fieldName = _arguments.second;
    var thirdArg = _arguments.third;

    await initialize(nitrite, collectionName);

    var indexDescriptor =
        await operations?.findIndex(Fields.withNames([fieldName]));

    await for (var pair in nitriteMap!.entries()) {
      var document = pair.$2;
      if (thirdArg is Generator) {
        document.put(fieldName, thirdArg(document));
      } else {
        document.put(fieldName, thirdArg);
      }
      // update all documents in parallel
      await nitriteMap!.put(pair.$1, document);
    }

    if (indexDescriptor != null) {
      await operations?.createIndex(
          Fields.withNames([fieldName]), indexDescriptor.indexType);
    }
  }
}

class RenameFieldCommand extends BaseCommand {
  final Triplet<String, String, String> _arguments;

  RenameFieldCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var collectionName = _arguments.first;
    var oldName = _arguments.second;
    var newName = _arguments.third;

    await initialize(nitrite, collectionName);

    var indexManager = IndexManager(collectionName, nitrite.config);
    try {
      await indexManager.initialize();
      var oldField = Fields.withNames([oldName]);
      var matchingIndexDescriptors =
          await indexManager.findMatchingIndexDescriptors(oldField);

      await for (var pair in nitriteMap!.entries()) {
        var document = pair.$2;
        if (document.containsKey(oldName)) {
          var value = document.get(oldName);
          document.put(newName, value);
          document.remove(oldName);

          // update all documents in parallel
          await nitriteMap!.put(pair.$1, document);
        }
      }

      if (matchingIndexDescriptors.isNotEmpty) {
        for (var indexDescriptor in matchingIndexDescriptors) {
          var indexType = indexDescriptor.indexType;

          var oldIndexFields = indexDescriptor.fields;
          var newIndexFields =
              _getNewIndexFields(oldIndexFields, oldName, newName);

          await operations!.dropIndex(indexDescriptor.fields);
          await operations!.createIndex(newIndexFields, indexType);
        }
      }
    } finally {
      await indexManager.close();
    }
  }

  Fields _getNewIndexFields(
      Fields oldIndexFields, String oldName, String newName) {
    var newIndexFields = Fields();
    for (var fieldName in oldIndexFields.fieldNames) {
      if (fieldName == oldName) {
        newIndexFields.addField(newName);
      } else {
        newIndexFields.addField(fieldName);
      }
    }
    return newIndexFields;
  }
}

class DeleteFieldCommand extends BaseCommand {
  final (String, String) _arguments;

  DeleteFieldCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var collectionName = _arguments.$1;
    var fieldName = _arguments.$2;

    await initialize(nitrite, collectionName);

    var indexDescriptor =
        await operations?.findIndex(Fields.withNames([fieldName]));

    await for (var pair in nitriteMap!.entries()) {
      var document = pair.$2;
      document.remove(fieldName);
      await nitriteMap!.put(pair.$1, document);
    }

    if (indexDescriptor != null) {
      await operations?.dropIndex(Fields.withNames([fieldName]));
    }
  }
}

class DropIndexCommand extends BaseCommand {
  final (String, Fields?) _arguments;

  DropIndexCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var collectionName = _arguments.$1;
    var fields = _arguments.$2;

    await initialize(nitrite, collectionName);

    if (fields == null) {
      await operations?.dropAllIndices();
    } else {
      await operations?.dropIndex(fields);
    }
  }
}

class CreateIndexCommand extends BaseCommand {
  final Triplet<String, Fields, String> _arguments;

  CreateIndexCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var collectionName = _arguments.first;
    var fields = _arguments.second;
    var indexType = _arguments.third;

    await initialize(nitrite, collectionName);

    await operations?.createIndex(fields, indexType);
  }
}
