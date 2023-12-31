import 'package:nitrite/nitrite.dart';

/// An abstract class that represents a plugin for working with Nitrite
/// database and provides methods for initializing and closing the
/// plugin instance.
abstract class NitritePlugin {
  /// Initializes the plugin instance.
  Future<void> initialize(NitriteConfig nitriteConfig);

  /// Closes the plugin instance.
  Future<void> close() async {}
}

/// An abstract class that represents a module encapsulating a set of
/// [NitritePlugin] objects.
abstract class NitriteModule {
  /// Returns the set of [NitritePlugin] encapsulated by this module.
  Set<NitritePlugin> get plugins;
}

/// Creates a Nitrite module with a set of [NitritePlugin]s.
///
/// Args:
///   plugins (List<NitritePlugin>): A list of [NitritePlugin] objects.
NitriteModule module(List<NitritePlugin> plugins) =>
    _NitriteModule(plugins.toSet());

///@nodoc
class _NitriteModule implements NitriteModule {
  @override
  final Set<NitritePlugin> plugins;

  _NitriteModule(this.plugins);
}
