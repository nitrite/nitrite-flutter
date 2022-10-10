import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/migration/migration.dart';

/// Represents a collection of database migration steps.
abstract class Instruction {
  /// Adds a migration step to the instruction set.
  void addStep(MigrationStep step);
}

/// Represents a custom instruction for database migration.
typedef CustomInstruction = Future<void> Function(Nitrite nitrite);

/// Represents an instruction type.
enum InstructionType {
  /// The add password instruction.
  addPassword,

  /// The change password instruction.
  changePassword,

  /// The drop collection instruction.
  dropCollection,

  /// The drop repository instruction.
  dropRepository,

  /// The custom instruction.
  custom,

  /// The collection rename instruction.
  collectionRename,

  /// The collection add field instruction.
  collectionAddField,

  /// The collection rename field instruction.
  collectionRenameField,

  /// The collection delete field instruction.
  collectionDeleteField,

  /// The collection drop index instruction.
  collectionDropIndex,

  /// The collection drop all indices instruction.
  collectionDropIndices,

  /// The collection create index instruction.
  collectionCreateIndex,

  /// The rename repository instruction.
  renameRepository,

  /// The repository add field instruction.
  repositoryAddField,

  /// The repository rename field instruction.
  repositoryRenameField,

  /// The repository delete field instruction.
  repositoryDeleteField,

  /// The repository change data type instruction.
  repositoryChangeDataType,

  /// The repository change id field instruction.
  repositoryChangeIdField,

  /// The repository drop index instruction.
  repositoryDropIndex,

  /// The repository drop indices instruction.
  repositoryDropIndices,

  /// The repository create index instruction.
  repositoryCreateIndex,
}

/// Represents a set of instruction to perform during database migration.
abstract class InstructionSet {
  /// Creates a [DatabaseInstruction].
  DatabaseInstruction forDatabase();

  /// Creates a [RepositoryInstruction].
  RepositoryInstruction forRepository<T>(NitriteMapper nitriteMapper,
      {EntityDecorator<T>? entityDecorator, String? key});

  /// Creates a [CollectionInstruction].
  CollectionInstruction forCollection(String collectionName);
}
