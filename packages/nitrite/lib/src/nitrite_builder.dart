import 'package:nitrite/nitrite.dart';

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
  Nitrite openOrCreate([String? username, String? password]) {
    nitriteConfig.autoConfigure();
    // TODO: add shutdown hook to close the db
    return NitriteDatabase(username, password, nitriteConfig);
  }
}
