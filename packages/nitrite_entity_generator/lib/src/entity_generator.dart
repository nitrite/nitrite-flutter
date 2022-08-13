import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/entity_parser.dart';
import 'package:nitrite_entity_generator/src/entity_writer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

class NitriteEntityGenerator extends GeneratorForAnnotation<Entity> {
  final _dartfmt = DartFormatter();

  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@Entity` can only be used on classes.',
        element: element,
      );
    }

    var entityParser = EntityParser(element);
    var entity = entityParser.parse();

    final library = Library((builder) {
      builder
        ..body.add(
            const Code("// ignore_for_file: invalid_use_of_internal_member\n"))
        ..body.add(const Code('\n'))
        ..body.add(EntityWriter(entity).write());
    });

    return _dartfmt.format('${library.accept(DartEmitter())}');
  }
}
