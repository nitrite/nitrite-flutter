import 'package:nitrite/nitrite.dart';


/// Represents a nitrite database plugin component.
abstract class NitritePlugin {
  /// Initializes the plugin instance.
  Future<void> initialize(NitriteConfig nitriteConfig);

  /// Closes the plugin instance.
  Future<void> close() async {}
}


/// Represents a nitrite plugin modules which may contains
/// one or more nitrite plugins.
abstract class NitriteModule {

  /// Creates a [NitriteModule] from a set of [NitritePlugin]s.
  static NitriteModule module(List<NitritePlugin> plugins) {
    return _NitriteModule(plugins.toSet());
  }

  /// Returns the set of [NitritePlugin] encapsulated by this module.
  Set<NitritePlugin> get plugins;
}

class _NitriteModule implements NitriteModule {
  @override
  final Set<NitritePlugin> plugins;

  _NitriteModule(this.plugins);
}
