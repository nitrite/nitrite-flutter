import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/migration/collection_instruction.dart';
import 'package:nitrite/src/migration/database_instruction.dart';
import 'package:nitrite/src/migration/instructions.dart';
import 'package:nitrite/src/migration/repository_instruction.dart';

class Migration {
  final Queue<MigrationStep> _migrationSteps = Queue();
  final int _fromVersion;
  final int _toVersion;
  final void Function(InstructionSet instructionSet) _instructionFunction;

  bool _executed = false;

  int get fromVersion => _fromVersion;
  int get toVersion => _toVersion;

  Migration(this._fromVersion, this._toVersion, this._instructionFunction);

  Queue<MigrationStep> steps() {
    if (!_executed) {
      _execute();
    }
    return _migrationSteps;
  }

  void _execute() {
    var instructionSet = _NitriteInstructionSet(_migrationSteps);
    _prepare(instructionSet);
    _executed = true;
  }

  void _prepare(InstructionSet instructionSet) {
    _instructionFunction(instructionSet);
  }
}

class MigrationStep {
  final InstructionType _instructionType;
  final dynamic _arguments;

  MigrationStep(this._instructionType, this._arguments);

  InstructionType get instructionType => _instructionType;

  dynamic get arguments => _arguments;
}

class _NitriteInstructionSet extends InstructionSet {
  final Queue<MigrationStep> _migrationSteps;

  _NitriteInstructionSet(this._migrationSteps);

  @override
  DatabaseInstruction forDatabase() {
    return _DatabaseInstruction(_migrationSteps);
  }

  @override
  CollectionInstruction forCollection(String collectionName) {
    return _CollectionInstruction(_migrationSteps, collectionName);
  }

  @override
  RepositoryInstruction forRepository<T>(NitriteMapper nitriteMapper,
      {String? key}) {
    return _RepositoryInstruction(
        _migrationSteps, getEntityName<T>(nitriteMapper), key);
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
