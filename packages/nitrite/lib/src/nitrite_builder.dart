import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/nitrite_database.dart';

/// A builder utility to create a [Nitrite] database instance.
class NitriteBuilder {
  final NitriteConfig _nitriteConfig;

  NitriteConfig get nitriteConfig => _nitriteConfig;

  /// Instantiates a new [NitriteBuilder].
  NitriteBuilder() : _nitriteConfig = NitriteConfig();

  /// Sets the embedded field separator character. Default value
  /// is `.`
  NitriteBuilder fieldSeparator(String separator) {
    nitriteConfig.setFieldSeparator(separator);
    return this;
  }

  /// Loads [NitriteModule] instance.
  NitriteBuilder loadModule(NitriteModule module) {
    nitriteConfig.loadModule(module);
    return this;
  }

  /// Adds instructions to perform during schema migration.
  NitriteBuilder addMigrations(List<Migration> migrations) {
    for (Migration migration in migrations) {
      nitriteConfig.addMigration(migration);
    }
    return this;
  }

  /// Sets the current schema version.
  NitriteBuilder schemaVersion(int version) {
    nitriteConfig.currentSchemaVersion(version);
    return this;
  }

  /// Opens or creates a new nitrite database. If it is an in-memory store,
  /// then it will create a new one. If it is a file based store, and if the file does not
  /// exists, then it will create a new file store and open; otherwise it will
  /// open the existing file store.
  Future<Nitrite> openOrCreate([String? username, String? password]) async {
    nitriteConfig.autoConfigure();
    // TODO: add shutdown hook to close the db
    var db = NitriteDatabase(nitriteConfig);
    await db.initialize(username, password);
    return db;
  }
}
