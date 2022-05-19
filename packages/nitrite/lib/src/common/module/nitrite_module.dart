import 'package:nitrite/nitrite.dart';

abstract class NitriteModule {

  static NitriteModule module(List<NitritePlugin> plugins) {
    return _NitriteModule(plugins.toSet());
  }

  Set<NitritePlugin> get plugins;
}

class _NitriteModule implements NitriteModule {
  @override
  final Set<NitritePlugin> plugins;

  _NitriteModule(this.plugins);
}
