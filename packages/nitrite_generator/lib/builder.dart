import 'package:build/build.dart';
import 'package:nitrite_generator/generator.dart';
import 'package:source_gen/source_gen.dart';

Builder nitriteEntityBuilder(BuilderOptions options) => PartBuilder([
      AnalyzerHintGenerator(),
      NitriteEntityGenerator(),
      ConverterGenerator(),
    ], '.no2.dart', options: options);
