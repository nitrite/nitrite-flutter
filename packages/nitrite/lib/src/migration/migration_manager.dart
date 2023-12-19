import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/migration/commands/collection_commands.dart';
import 'package:nitrite/src/migration/commands/commands.dart';
import 'package:nitrite/src/migration/commands/db_commands.dart';
import 'package:nitrite/src/migration/commands/repository_commands.dart';
import 'package:nitrite/src/migration/instructions.dart';
import 'package:nitrite/src/migration/migration.dart';

/// @nodoc
class MigrationManager {
  final Nitrite _database;
  final NitriteMapper _nitriteMapper;

  late NitriteConfig _nitriteConfig;
  late StoreMetaData _storeMetaData;

  MigrationManager(this._database, this._nitriteMapper);

  Future<void> initialize() async {
    _nitriteConfig = _database.config;
    _storeMetaData = await _database.databaseMetaData;
  }

  Future<void> doMigrate() async {
    if (_isMigrationNeeded) {
      var existingVersion = _storeMetaData.schemaVersion!;
      var incomingVersion = _nitriteConfig.schemaVersion;

      var migrationPath = _findMigrationPath(existingVersion, incomingVersion);
      if (migrationPath.isEmpty) {
        // close the database
        try {
          await _database.close();
        } catch (e, stackTrace) {
          throw NitriteIOException('Failed to close database',
              stackTrace: stackTrace, cause: e);
        }

        throw MigrationException('Schema version mismatch, no migration path'
            ' found from version $existingVersion to $incomingVersion');
      }

      var length = migrationPath.length;
      for (var i = 0; i < length; i++) {
        var migration = migrationPath.removeFirst();
        var migrationSteps = migration.steps();
        await _executeMigrationSteps(migrationSteps);
      }
    }
  }

  bool get _isMigrationNeeded {
    var existingVersion = _storeMetaData.schemaVersion;
    var incomingVersion = _nitriteConfig.schemaVersion;

    if (existingVersion == null) {
      throw MigrationException(
          'Corrupted database, no version information found');
    }

    return existingVersion != incomingVersion;
  }

  Queue<Migration> _findMigrationPath(int start, int end) {
    if (start == end) {
      return Queue<Migration>();
    }

    bool migrateUp = end > start;
    return _findUpMigrationPath(migrateUp, start, end);
  }

  Queue<Migration> _findUpMigrationPath(bool upgrade, int start, int end) {
    var result = Queue<Migration>();
    while (upgrade ? start < end : start > end) {
      var targetNodes = _nitriteConfig.migrations[start];
      if (targetNodes == null) {
        return Queue<Migration>();
      }

      Iterable<int> keySet;
      if (upgrade) {
        keySet = targetNodes.keys.toList().reversed;
      } else {
        keySet = targetNodes.keys;
      }

      bool found = false;
      for (var targetVersion in keySet) {
        bool shouldAddToPath;
        if (upgrade) {
          shouldAddToPath = targetVersion <= end && targetVersion > start;
        } else {
          shouldAddToPath = targetVersion >= end && targetVersion < start;
        }

        if (shouldAddToPath && targetNodes.containsKey(targetVersion)) {
          var migration = targetNodes[targetVersion]!;
          migration.nitriteMapper = _nitriteMapper;

          result.add(migration);
          start = targetVersion;
          found = true;
          break;
        }
      }

      if (!found) {
        return Queue<Migration>();
      }
    }
    return result;
  }

  Future<void> _executeMigrationSteps(
      Queue<MigrationStep> migrationSteps) async {
    if (migrationSteps.isNotEmpty) {
      var length = migrationSteps.length;
      for (var i = 0; i < length; i++) {
        var migrationStep = migrationSteps.removeFirst();
        await _executeStep(migrationStep);
      }
    }

    var metadata = await _database.databaseMetaData;
    metadata.schemaVersion = _nitriteConfig.schemaVersion;

    var info = await _database.getStore().openMap<String, Document>(storeInfo);
    await info.put(storeInfo, metadata.getInfo());
  }

  Future<void> _executeStep(MigrationStep step) async {
    try {
      Command command;
      switch (step.instructionType) {
        case InstructionType.addUser:
          command = AddPasswordCommand(step.arguments as (String, String));
          break;
        case InstructionType.changePassword:
          command =
              ChangePasswordCommand(step.arguments as (String, String, String));
          break;
        case InstructionType.dropCollection:
          command = DropCollectionCommand(step.arguments as String);
          break;
        case InstructionType.dropRepository:
          command = DropRepositoryCommand(step.arguments as (String, String?));
          break;
        case InstructionType.custom:
          command = CustomCommand(step.arguments as CustomInstruction);
          break;
        case InstructionType.collectionRename:
          command = CollectionRenameCommand(step.arguments as (String, String));
          break;
        case InstructionType.collectionAddField:
          command =
              AddFieldCommand(step.arguments as (String, String, dynamic));
          break;
        case InstructionType.collectionRenameField:
          command =
              RenameFieldCommand(step.arguments as (String, String, String));
          break;
        case InstructionType.collectionDeleteField:
          command = DeleteFieldCommand(step.arguments as (String, String));
          break;
        case InstructionType.collectionDropIndex:
          command = DropIndexCommand(step.arguments as (String, Fields?));
          break;
        case InstructionType.collectionDropIndices:
          command = DropIndexCommand((step.arguments as String, null));
          break;
        case InstructionType.collectionCreateIndex:
          command =
              CreateIndexCommand(step.arguments as (String, Fields, String));
          break;
        case InstructionType.renameRepository:
          command = RepositoryRenameCommand(
              step.arguments as (String, String?, String, String?));
          break;
        case InstructionType.repositoryAddField:
          var args = step.arguments as (String, String?, String, dynamic);
          var repositoryName = findRepositoryNameByTypeName(args.$1, args.$2);
          command = AddFieldCommand((repositoryName, args.$3, args.$4));
          break;
        case InstructionType.repositoryRenameField:
          var args = step.arguments as (String, String?, String, String);
          var repositoryName = findRepositoryNameByTypeName(args.$1, args.$2);
          command = RenameFieldCommand((repositoryName, args.$3, args.$4));
          break;
        case InstructionType.repositoryDeleteField:
          var args = step.arguments as (String, String?, String);
          var repositoryName = findRepositoryNameByTypeName(args.$1, args.$2);
          command = DeleteFieldCommand((repositoryName, args.$3));
          break;
        case InstructionType.repositoryChangeDataType:
          command = ChangeDataTypeCommand(
              step.arguments as (String, String?, String, TypeConverter));
          break;
        case InstructionType.repositoryChangeIdField:
          command = ChangeIdFieldCommand(
              step.arguments as (String, String?, Fields, Fields));
          break;
        case InstructionType.repositoryDropIndex:
          var args = step.arguments as (String, String?, Fields);
          var repositoryName = findRepositoryNameByTypeName(args.$1, args.$2);
          command = DropIndexCommand((repositoryName, args.$3));
          break;
        case InstructionType.repositoryDropIndices:
          var args = step.arguments as (String, String?);
          var repositoryName = findRepositoryNameByTypeName(args.$1, args.$2);
          command = DropIndexCommand((repositoryName, null));
          break;
        case InstructionType.repositoryCreateIndex:
          var args = step.arguments as (String, String?, Fields, String);
          var repositoryName = findRepositoryNameByTypeName(args.$1, args.$2);
          command = CreateIndexCommand((repositoryName, args.$3, args.$4));
          break;
      }

      await command.execute(_database);
      await command.close();
    } catch (e, s) {
      throw MigrationException(
          'Migration failed during ${step.instructionType.name} stage.',
          cause: e,
          stackTrace: s);
    }
  }
}
