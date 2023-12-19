import 'package:nitrite_entity_generator/src/id_field_parser.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test("Parse Id field", () async {
    final fieldElement = await generateFieldElement('''
      @Id()
      final int id;
    ''');

    final idField = IdFieldParser(fieldElement).parse();

    expect(idField.fieldName, equals('id'));
    expect(idField.encodedFieldNames, isEmpty);
    expect(idField.isEmbedded, isFalse);
  });

  test("Parse Id field with nullable", () async {
    final fieldElement = await generateFieldElement('''
      @Id()
      final int? id;
    ''');

    final idField = IdFieldParser(fieldElement).parse();

    expect(idField.fieldName, equals('id'));
    expect(idField.encodedFieldNames, isEmpty);
    expect(idField.isEmbedded, isFalse);
  });

  test("Parse Id field with custom name", () async {
    final fieldElement = await generateFieldElement('''
      @Id(fieldName: "customName")
      final int? id;
    ''');

    final idField = IdFieldParser(fieldElement).parse();

    expect(idField.fieldName, equals('customName'));
    expect(idField.encodedFieldNames, isEmpty);
    expect(idField.isEmbedded, isFalse);
  });

  test("Parse Id field with custom name and embedded field", () async {
    final fieldElement = await generateFieldElement('''
      @Id(fieldName: "customName", embeddedFields: ["name"])
      final int? id;
    ''');

    expect(() => IdFieldParser(fieldElement).parse(),
        throwsA(TypeMatcher<InvalidGenerationSourceError>()));
  });

  test("Parse Id field with custom type and no embedded field", () async {
    final fieldElement = await generateFieldElement('''
      @Id(fieldName: "customName")
      final FooId? id;
    ''');

    expect(() => IdFieldParser(fieldElement).parse(),
        throwsA(TypeMatcher<InvalidGenerationSourceError>()));
  });

  test("Parse Id field with custom type and embedded field", () async {
    final fieldElement = await generateFieldElement('''
      @Id(fieldName: "customName", embeddedFields: ["name"])
      final FooId? id;
    ''');

    final idField = IdFieldParser(fieldElement).parse();

    expect(idField.fieldName, equals('customName'));
    expect(idField.encodedFieldNames, isNotEmpty);
    expect(idField.isEmbedded, isTrue);
    expect(idField.encodedFieldNames, equals(['customName.name']));
    expect(idField.embeddedFields, equals(['name']));
  });

  test("Parse Id field with invalid type and embedded field", () async {
    final fieldElement = await generateFieldElement('''
      @Id(fieldName: "customName", embeddedFields: ["name"])
      final FooId2 id;
    ''');

    expect(() => IdFieldParser(fieldElement).parse(),
        throwsA(TypeMatcher<InvalidGenerationSourceError>()));
  });
}
