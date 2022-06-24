import 'package:nitrite/nitrite.dart';

/// Represents a nitrite store module to load as a
/// storage engine for the database.
abstract class StoreModule extends NitriteModule {
  /// Gets the [NitriteStore] instance from this module.
  NitriteStore<Config> getStore<Config extends StoreConfig>();
}
