import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/migration/instructions.dart';
import 'package:nitrite/src/migration/migration.dart';

/// Represents a migration instruction set for the nitrite database.
abstract class DatabaseInstruction implements Instruction {
  final NitriteMapper _nitriteMapper;

  DatabaseInstruction(this._nitriteMapper);

  /// Adds an instruction to set an user authentication to the database.
  DatabaseInstruction addUser(String username, String password) {
    MigrationStep migrationStep =
        MigrationStep(InstructionType.addUser, (username, password));
    addStep(migrationStep);
    return this;
  }

  /// Adds an instruction to change the password for the user
  /// authentication to the database.
  DatabaseInstruction changePassword(
      String username, String oldPassword, String newPassword) {
    MigrationStep migrationStep = MigrationStep(
        InstructionType.changePassword, (username, oldPassword, newPassword));
    addStep(migrationStep);
    return this;
  }

  /// Adds an instruction to drop a [NitriteCollection] from the database.
  DatabaseInstruction dropCollection(String collectionName) {
    MigrationStep migrationStep =
        MigrationStep(InstructionType.dropCollection, collectionName);
    addStep(migrationStep);
    return this;
  }

  /// Adds an instruction to drop a keyed [ObjectRepository] from the database.
  DatabaseInstruction dropRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? entityName, String? key}) {
    var derivedName = entityName == null || entityName.isEmpty
        ? entityDecorator != null
            ? entityDecorator.entityName
            : getEntityName<T>(_nitriteMapper)
        : entityName;

    MigrationStep migrationStep =
        MigrationStep(InstructionType.dropRepository, (derivedName, key));
    addStep(migrationStep);
    return this;
  }

  /// Adds a custom instruction to perform a user defined
  /// operation on the database.
  DatabaseInstruction customInstruction(CustomInstruction instruction) {
    MigrationStep migrationStep =
        MigrationStep(InstructionType.custom, instruction);
    addStep(migrationStep);
    return this;
  }
}
