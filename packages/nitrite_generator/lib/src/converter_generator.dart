import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_generator/src/converter_parser.dart';
import 'package:source_gen/source_gen.dart';

import 'converter_writer.dart';

// Generates codes for @GenerateConverter annotation.
class ConverterGenerator extends GeneratorForAnnotation<Convertable> {
  final _dartfmt = DartFormatter();

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    // @GenerateConverter is class level annotation only.
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@GenerateConverter` can only be used on classes.',
        element: element,
      );
    }

    // parse the metadata from the annotation
    var converterParser = ConverterParser(element);
    var converter = converterParser.parse();

    final library = Library((builder) {
      builder
        ..body.add(const Code('\n'))
        ..body.add(ConverterWriter(converter).write());
    });

    return _dartfmt.format('${library.accept(DartEmitter())}');
  }
}
