import 'dart:ffi';

import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';

void main() {
  group('Object Repository Negative Test Suite', () {
    late Nitrite db;

    setUp(() async {
      setUpLog();

      db = await Nitrite.builder().openOrCreate();
      var documentMapper = db.config.nitriteMapper as SimpleDocumentMapper;
      documentMapper.registerEntityConverter(WithObjectIdConverter());
      documentMapper.registerEntityConverter(WithOutIdConverter());
      documentMapper.registerEntityConverter(WithEmptyStringIdConverter());
      documentMapper.registerEntityConverter(WithNullIdConverter());
      documentMapper.registerEntityConverter(EmployeeConverter());
      documentMapper.registerEntityConverter(CompanyConverter());
      documentMapper.registerEntityConverter(NoteConverter());
      documentMapper.registerEntityConverter(WithNitriteIdConverter());
      documentMapper.registerEntityConverter(WithCircularReferenceConverter());
    });

    tearDown(() async {
      if (!db.isClosed) {
        await db.close();
      }
    });

    test('Test With Circular Reference', () async {
      var repository = await db.getRepository<WithCircularReference>();
      var parent = WithCircularReference();
      parent.name = 'parent';
      var child = WithCircularReference();
      child.name = 'child';
      child.parent = parent;
      // circular reference
      parent.parent = child;

      expect(() async => await repository.insert(child),
          throwsObjectMappingException);
    });

    test('Test With Empty String Id', () async {
      var repository = await db.getRepository<WithEmptyStringId>(
          entityDecorator: WithEmptyStringIdEntityDecorator());
      var object = WithEmptyStringId(name: '');

      expect(() async => await repository.insert(object),
          throwsInvalidIdException);
    });

    test('Test With Null Id', () async {
      var repository = await db.getRepository<WithNullId>();
      var object = WithNullId();

      expect(() async => await repository.insert(object),
          throwsInvalidIdException);
    });

    test('Test With Built-in Type Repository', () async {
      expect(() async => await db.getRepository<String>(),
          throwsValidationException);

      expect(
          () async => await db.getRepository<num>(), throwsValidationException);

      expect(
          () async => await db.getRepository<int>(), throwsValidationException);

      expect(() async => await db.getRepository<double>(),
          throwsValidationException);

      expect(() async => await db.getRepository<DateTime>(),
          throwsValidationException);

      expect(() async => await db.getRepository<Duration>(),
          throwsValidationException);

      expect(() async => await db.getRepository<Runes>(),
          throwsValidationException);

      expect(() async => await db.getRepository<Symbol>(),
          throwsValidationException);

      expect(() async => await db.getRepository<void>(),
          throwsValidationException);

      expect(() async => await db.getRepository<Void>(),
          throwsValidationException);

      expect(() async => await db.getRepository<NitriteId>(),
          throwsValidationException);
    });

    test('Test Update No Id', () async {
      var repository = await db.getRepository<WithOutId>(
          entityDecorator: WithOutIdEntityDecorator());

      var object = WithOutId(name: 'name', number: 1);
      expect(() async => await repository.updateOne(object),
          throwsNotIdentifiableException);
    });

    test('Test Remove No Id', () async {
      var repository = await db.getRepository<WithOutId>(
          entityDecorator: WithOutIdEntityDecorator());

      var object = WithOutId(name: 'name', number: 1);
      expect(() async => await repository.removeOne(object),
          throwsNotIdentifiableException);
    });

    test('Test Projection Failed Instantiate', () async {
      var repository = await db.getRepository<WithOutId>(
          entityDecorator: WithOutIdEntityDecorator());

      var object = WithOutId(name: 'name', number: 1);
      await repository.insert(object);

      var cursor = repository.find();
      expect(() async => await cursor.project<NitriteId>().toList(),
          throwsValidationException);
    });

    test('Test Null Insert', () async {
      var repository = await db.getRepository<WithOutId?>(
          entityDecorator: WithOutIdEntityDecorator());

      expect(() async => await repository.insert(null),
          throwsValidationException);
    });

    test('Test Get By Null Id', () async {
      var repository = await db.getRepository<WithNitriteId>();
      var object = WithNitriteId();
      object.name = 'test';

      await repository.insert(object);
      expect(
          () async => await repository.getById(null), throwsInvalidIdException);
    });

    test('Test External Nitrite Id', () async {
      var repository = await db.getRepository<WithNitriteId>();
      var object = WithNitriteId();
      object.idField = NitriteId.createId('1');
      object.name = 'test';
      var result = await repository.updateOne(object, insertIfAbsent: true);
      expect(result.getAffectedCount(), 1);

      var id = result.first;
      object = WithNitriteId();
      object.idField = id;
      object.name = 'test';
      result = await repository.updateOne(object, insertIfAbsent: true);
      expect(id.idValue, isNot(result.first.idValue));
    });

    test('Test Get by Wrong Id Type', () async {
      var repository = await db.getRepository<WithNitriteId>();
      var object = WithNitriteId();
      object.name = 'test';

      var result = await repository.insert(object);
      
      expect(result.getAffectedCount(), 1);
      expect(
          () async => await repository.getById("1"), throwsInvalidIdException);
    });
  });
}
