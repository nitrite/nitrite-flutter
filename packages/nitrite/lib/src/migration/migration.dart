import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/migration/instructions.dart';

/// Represents the database migration operation. A migration is a way to modify
/// the structure of a database from one version to another. It contains a queue
/// of [MigrationStep]s that need to be executed in order to migrate the database
/// from the start version to the end version.
class Migration {
  final Queue<MigrationStep> _migrationSteps = Queue();
  final int _fromVersion;
  final int _toVersion;
  final void Function(InstructionSet instructionSet) _instructionFunction;

  late NitriteMapper _nitriteMapper;

  bool _executed = false;

  /// Returns the version number from which the migration is being performed.
  int get fromVersion => _fromVersion;

  /// Returns the version number to which the migration is being performed.
  int get toVersion => _toVersion;

  /// Sets the [NitriteMapper] instance used by the migration.
  set nitriteMapper(NitriteMapper value) => _nitriteMapper = value;

  Migration(this._fromVersion, this._toVersion, this._instructionFunction);

  /// Returns a queue of [MigrationStep]s to be executed for the migration.
  Queue<MigrationStep> steps() {
    if (!_executed) {
      _execute();
    }
    return _migrationSteps;
  }

  void _execute() {
    var instructionSet =
        _NitriteInstructionSet(_migrationSteps, _nitriteMapper);
    _prepare(instructionSet);
    _executed = true;
  }

  void _prepare(InstructionSet instructionSet) {
    _instructionFunction(instructionSet);
  }
}

/// A class representing a migration step in Nitrite database.
class MigrationStep {
  final InstructionType _instructionType;
  final dynamic _arguments;

  MigrationStep(this._instructionType, this._arguments);

  /// Returns the instruction type of the migration instruction.
  InstructionType get instructionType => _instructionType;

  /// Returns the arguments passed to the migration function.
  dynamic get arguments => _arguments;
}

class _NitriteInstructionSet extends InstructionSet {
  final Queue<MigrationStep> _migrationSteps;
  final NitriteMapper _nitriteMapper;

  _NitriteInstructionSet(this._migrationSteps, this._nitriteMapper);

  @override
  DatabaseInstruction forDatabase() {
    return _DatabaseInstruction(_migrationSteps);
  }

  @override
  CollectionInstruction forCollection(String collectionName) {
    return _CollectionInstruction(_migrationSteps, collectionName);
  }

  @override
  RepositoryInstruction forRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key}) {
    var entityName = entityDecorator != null
        ? entityDecorator.entityName
        : getEntityName<T>(_nitriteMapper);
    return _RepositoryInstruction(_migrationSteps, entityName, key);
  }
}

class _DatabaseInstruction extends DatabaseInstruction {
  final Queue<MigrationStep> _migrationSteps;

  _DatabaseInstruction(this._migrationSteps);

  @override
  void addStep(MigrationStep step) {
    _migrationSteps.add(step);
  }
}

class _CollectionInstruction extends CollectionInstruction {
  final Queue<MigrationStep> _migrationSteps;
  final String _collectionName;

  _CollectionInstruction(this._migrationSteps, this._collectionName);

  @override
  String get collectionName => _collectionName;

  @override
  void addStep(MigrationStep step) {
    _migrationSteps.add(step);
  }
}

class _RepositoryInstruction extends RepositoryInstruction {
  final Queue<MigrationStep> _migrationSteps;
  final String _entityName;
  final String? _key;

  _RepositoryInstruction(this._migrationSteps, this._entityName, this._key);

  @override
  String get entityName => _entityName;

  @override
  String? get key => _key;

  @override
  void addStep(MigrationStep step) {
    _migrationSteps.add(step);
  }
}
