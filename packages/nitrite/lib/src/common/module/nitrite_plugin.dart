import 'package:nitrite/src/nitrite_config.dart';

abstract class NitritePlugin {
  void initialize(NitriteConfig nitriteConfig);

  void close() {}
}
