import 'dart:async';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:nitrite/nitrite.dart' as no2;
import 'package:source_gen/source_gen.dart';

class AnalyzerHintGenerator extends Generator {
  final _dartfmt = DartFormatter();

  // generates hint only where nitrite annotations are present
  final entityChecker = TypeChecker.fromRuntime(no2.Entity);
  final converterChecker = TypeChecker.fromRuntime(no2.GenerateConverter);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final values = <String>{};
    // @Entity found
    bool isEntity = library.annotatedWith(entityChecker).isNotEmpty;
    // @GenerateConverter found
    bool isConverter = library.annotatedWith(converterChecker).isNotEmpty;

    if (isEntity || isConverter) {
      final lib = Library((builder) {
        builder
          ..body.add(const Code(
              "// ignore_for_file: invalid_use_of_internal_member\n"))
          ..body.add(const Code('\n'));
      });

      return _dartfmt.format('${lib.accept(DartEmitter())}');
    } else {
      return values.join('\n\n');
    }
  }
}
