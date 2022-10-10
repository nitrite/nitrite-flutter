import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/migration/instructions.dart';
import 'package:nitrite/src/migration/migration.dart';

/// Represents a migration instruction set for the nitrite database.
abstract class DatabaseInstruction implements Instruction {
  /// Adds an instruction to set an user authentication to the database.
  DatabaseInstruction addPassword(String username, String password) {
    MigrationStep migrationStep =
        MigrationStep(InstructionType.addPassword, Pair(username, password));
    addStep(migrationStep);
    return this;
  }

  /// Adds an instruction to change the password for the user
  /// authentication to the database.
  DatabaseInstruction changePassword(
      String username, String oldPassword, String newPassword) {
    MigrationStep migrationStep = MigrationStep(InstructionType.changePassword,
        Triplet(username, oldPassword, newPassword));
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
  DatabaseInstruction dropRepository<T>(NitriteMapper nitriteMapper,
      {EntityDecorator<T>? entityDecorator, String? key}) {
    var entityName = entityDecorator != null
        ? entityDecorator.entityName
        : getEntityName<T>(nitriteMapper);

    MigrationStep migrationStep =
        MigrationStep(InstructionType.dropRepository, Pair(entityName, key));
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
