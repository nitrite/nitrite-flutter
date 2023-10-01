import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/nitrite_database.dart';

/// The NitriteBuilder class provides a fluent API to configure and create a
/// Nitrite database instance.
class NitriteBuilder {
  final NitriteConfig _nitriteConfig;

  /// The Nitrite configuration object.
  NitriteConfig get nitriteConfig => _nitriteConfig;

  /// Instantiates a new [NitriteBuilder].
  NitriteBuilder() : _nitriteConfig = NitriteConfig();

  /// Sets the field separator character for Nitrite. It is used to separate
  /// field names in a nested document. For example, if a document has a field
  /// `address` which is a nested document, then the field `street` of the
  /// nested document can be accessed using `address.street` syntax.
  ///
  /// The default value is `.`.
  NitriteBuilder fieldSeparator(String separator) {
    nitriteConfig.setFieldSeparator(separator);
    return this;
  }

  /// Loads a Nitrite module into the Nitrite database. The module can be
  /// used to extend the functionality of Nitrite.
  NitriteBuilder loadModule(NitriteModule module) {
    nitriteConfig.loadModule(module);
    return this;
  }

  /// Adds one or more migrations to the Nitrite database. Migrations are used
  /// to upgrade the database schema when the application version changes.
  NitriteBuilder addMigrations(List<Migration> migrations) {
    for (Migration migration in migrations) {
      nitriteConfig.addMigration(migration);
    }
    return this;
  }

  /// Sets the schema version for the Nitrite database.
  NitriteBuilder schemaVersion(int version) {
    nitriteConfig.currentSchemaVersion(version);
    return this;
  }

  /// Opens or creates a new Nitrite database with the given username and password.
  /// If it is configured as in-memory database, then it will create a new database
  /// everytime. If it is configured as a file based database, and if the file
  /// does not exist, then it will create a new file store and open the database;
  /// otherwise it will open the existing database file.
  /// 
  /// If the username and password is not provided, then it will open the database
  /// without any authentication.
  /// 
  /// If the username and password both are provided, then it will open the database
  /// with authentication. If the database is not already created, then it will
  /// create a new database with the given username and password.
  /// 
  /// If the database is already created, then it will open the database with the
  /// given username and password. If the username and password is not valid, then
  /// it will throw an exception.
  /// 
  /// NOTE: Both username and password must be provided or both must be null.
  Future<Nitrite> openOrCreate({String? username, String? password}) async {
    await nitriteConfig.autoConfigure();
    var db = NitriteDatabase(nitriteConfig);
    await db.initialize(username, password);
    return db;
  }
}
