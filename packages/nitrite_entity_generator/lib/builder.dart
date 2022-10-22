import 'package:build/build.dart';
import 'package:nitrite_entity_generator/generator.dart';
import 'package:nitrite_entity_generator/src/converter_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder nitriteEntityBuilder(BuilderOptions options) =>
    PartBuilder([NitriteEntityGenerator(), ConverterGenerator()], '.no2.dart',
        options: options);
