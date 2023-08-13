import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/common.dart';
import 'package:nitrite_entity_generator/src/converter_parser.dart';
import 'package:nitrite_entity_generator/src/entity_parser.dart';
import 'package:nitrite_entity_generator/src/extensions.dart';
import 'package:source_gen/source_gen.dart';

Future<ClassElement> createClassElement(final String clazz) async {
  final library = await resolveSource('''
      library test;
      
      import 'dart:typed_data';
      import 'package:nitrite/nitrite.dart';
      
      $clazz
      ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return library.classes.first;
}

Future<FieldElement> generateFieldElement(final String field) async {
  final library = await resolveSource('''
      library test;
      
      import 'dart:typed_data';
      import 'package:nitrite/nitrite.dart';
      
      class Foo {
        $field
      }
      
      class FooId {
        final String id;
        final String name;
        
        FooId(this.id, this.name);
      }
      ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return library.classes.first.fields.first;
}

Future<EntityInfo> createEntityInfo(final String entity) async {
  final library = await resolveSource('''
      library test;
      
      import 'package:nitrite/nitrite.dart';
            
      $entity
      ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return library.classes
      .where((element) => element.hasAnnotation(Entity))
      .map((element) => EntityParser(element).parse())
      .first;
}

Future<ConverterInfo> createConverterInfo(final String converter) async {
  final library = await resolveSource('''
      library test;
      
      import 'package:nitrite/nitrite.dart';
            
      $converter
      ''', (resolver) async {
    return resolver
        .findLibraryByName('test')
        .then((value) => ArgumentError.checkNotNull(value))
        .then((value) => LibraryReader(value));
  });

  return library.classes
      .where((element) => element.hasAnnotation(GenerateConverter))
      .map((element) => ConverterParser(element).parse())
      .first;
}
