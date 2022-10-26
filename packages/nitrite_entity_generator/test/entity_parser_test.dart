import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/entity_parser.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('Parse entity', () async {
    final classElement = await createClassElement('''
      @Entity(name: 'person', indices: [
        Index(fields: ['name'], type: IndexType.nonUnique),
      ])
      class Person {
        @Id(fieldName: 'person_id')
        int? personId;
        
        String? name;
        
        Person([this.personId, this.name]);
      }
    ''');

    final entity = EntityParser(classElement).parse();

    expect(entity.entityName, 'person');
    expect(entity.className, 'Person');
    expect(entity.entityIndices.length, 1);
    expect(entity.entityIndices, [
      EntityIndex(["name"], IndexType.nonUnique)
    ]);
    expect(entity.entityId, isNotNull);
    expect(entity.entityId!.fieldName, 'person_id');
    expect(entity.entityId!.embeddedFieldNames, isEmpty);
  });

  test('Parse entity without default constructor', () async {
    final classElement = await createClassElement('''
      @Entity(name: 'person', indices: [
        Index(fields: ['name'], type: IndexType.nonUnique),
      ])
      class Person {
        @Id(fieldName: 'person_id')
        int? personId;
        
        String? name;
        
        Person(this.personId, [this.name]);
      }
    ''');


    expect(() => EntityParser(classElement).parse(),
        throwsA(TypeMatcher<InvalidGenerationSourceError>()));
  });

  test('Parse entity without entity name', () async {
    final classElement = await createClassElement('''
      @Entity(indices: [
        Index(fields: ['name'], type: IndexType.nonUnique),
      ])
      class Person {
        @Id(fieldName: 'person_id')
        int? personId;
        
        String? name;
        
        Person([this.personId, this.name]);
      }
    ''');

    final entity = EntityParser(classElement).parse();

    expect(entity.entityName, 'Person');
    expect(entity.className, 'Person');
    expect(entity.entityIndices.length, 1);
    expect(entity.entityIndices, [
      EntityIndex(["name"], IndexType.nonUnique)
    ]);
    expect(entity.entityId, isNotNull);
    expect(entity.entityId!.fieldName, 'person_id');
    expect(entity.entityId!.embeddedFieldNames, isEmpty);
  });

  test('Parse entity without any indexes', () async {
    final classElement = await createClassElement('''
      @Entity()
      class Person {
        @Id(fieldName: 'person_id')
        int? personId;
        
        String? name;
        
        Person([this.personId, this.name]);
      }
    ''');

    final entity = EntityParser(classElement).parse();

    expect(entity.entityName, 'Person');
    expect(entity.className, 'Person');
    expect(entity.entityIndices.length, 0);
    expect(entity.entityId, isNotNull);
    expect(entity.entityId!.fieldName, 'person_id');
    expect(entity.entityId!.embeddedFieldNames, isEmpty);
  });

  test('Parse entity without Id', () async {
    final classElement = await createClassElement('''
      @Entity()
      class Person {
        int? personId;
        
        String? name;
        
        Person([this.personId, this.name]);
      }
    ''');

    final entity = EntityParser(classElement).parse();

    expect(entity.entityName, 'Person');
    expect(entity.className, 'Person');
    expect(entity.entityIndices.length, 0);
    expect(entity.entityId, isNull);
  });

  test('Parse entity without Id field name', () async {
    final classElement = await createClassElement('''
      @Entity(name: 'person', indices: [
        Index(fields: ['name'], type: IndexType.nonUnique),
      ])
      class Person {
        @Id()
        int? personId;
        
        String? name;
        
        Person([this.personId, this.name]);
      }
    ''');

    final entity = EntityParser(classElement).parse();

    expect(entity.entityName, 'person');
    expect(entity.className, 'Person');
    expect(entity.entityIndices.length, 1);
    expect(entity.entityIndices, [
      EntityIndex(["name"], IndexType.nonUnique)
    ]);
    expect(entity.entityId, isNotNull);
    expect(entity.entityId!.fieldName, 'personId');
    expect(entity.entityId!.embeddedFieldNames, isEmpty);
  });

  test('Parse entity without Id field name', () async {
    final classElement = await createClassElement('''
      @Entity(name: 'person', indices: [
        Index(fields: ['name'], type: IndexType.nonUnique),
      ])
      class Person {
        @Id()
        int? personId;
        
        String? name;
        
        Person([this.personId, this.name]);
      }
    ''');

    final entity = EntityParser(classElement).parse();

    expect(entity.entityName, 'person');
    expect(entity.className, 'Person');
    expect(entity.entityIndices.length, 1);
    expect(entity.entityIndices, [
      EntityIndex(["name"], IndexType.nonUnique)
    ]);
    expect(entity.entityId, isNotNull);
    expect(entity.entityId!.fieldName, 'personId');
    expect(entity.entityId!.embeddedFieldNames, isEmpty);
  });

  test('Parse entity Id with wrong embedded fields', () async {
    final classElement = await createClassElement('''
      @Entity(name: 'person', indices: [
        Index(fields: ['name'], type: IndexType.nonUnique),
      ])
      class Person {
        @Id(embeddedFields: ['isbn', 'book_name'])
        PersonId? personId;
        
        String? name;
        
        Person([this.personId, this.name]);
      }
    ''');

    expect(() => EntityParser(classElement).parse(),
        throwsA(TypeMatcher<InvalidGenerationSourceError>()));
  });

  test('Parse entity Id with embedded fields', () async {
    final classElement = await createClassElement('''
      @Entity(name: 'person', indices: [
        Index(fields: ['name'], type: IndexType.nonUnique),
      ])
      class Person {
        @Id(embeddedFields: ['age', 'dob'])
        PersonId? personId;
        
        String? name;
        
        Person([this.personId, this.name]);
      }
      
      class PersonId {
        int? age;
        double? dob;
        
        PersonId([this.age, this.dob]);
      }
    ''');

    final entity = EntityParser(classElement).parse();

    expect(entity.entityName, 'person');
    expect(entity.className, 'Person');
    expect(entity.entityIndices.length, 1);
    expect(entity.entityIndices, [
      EntityIndex(["name"], IndexType.nonUnique)
    ]);
    expect(entity.entityId, isNotNull);
    expect(entity.entityId!.fieldName, 'personId');
    expect(entity.entityId!.subFields, ['age', 'dob']);
    expect(entity.entityId!.embeddedFieldNames, isNotEmpty);
    expect(
        entity.entityId!.embeddedFieldNames, ['personId.age', 'personId.dob']);
  });

  test("Parse entity with multiple id", () async {
    final classElement = await createClassElement('''
      @Entity(name: 'person', indices: [
        Index(fields: ['name'], type: IndexType.nonUnique),
      ])
      class Person {
        @Id(embeddedFields: ['age', 'dob'])
        PersonId? personId;
        
        @Id()
        String? name;
        
        Person([this.personId, this.name]);
      }
      
      class PersonId {
        int? age;
        double? dob;
        
        PersonId([this.age, this.dob]);
      }
    ''');

    expect(() => EntityParser(classElement).parse(),
        throwsA(TypeMatcher<InvalidGenerationSourceError>()));
  });
}
