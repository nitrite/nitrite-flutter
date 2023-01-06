import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';

import 'base_object_repository_test_loader.dart';
import 'data/test_objects.dart';

void main() {
  group('Nitrite Id as Identifier Test Suite', () {
    late Nitrite db;
    late ObjectRepository<WithNitriteId> repo;

    setUp(() async {
      setUpLog();
      
      db = await Nitrite.builder().fieldSeparator('.').openOrCreate();
      var mapper = db.config.nitriteMapper as SimpleDocumentMapper;
      mapper.registerEntityConverter(WithNitriteIdConverter());
      repo = await db.getRepository<WithNitriteId>();
    });

    tearDown(() async {
      if (!db.isClosed) {
        await db.close();
      }
    });

    test('Test Nitrite Id Field', () async {
      var item1 = WithNitriteId();
      item1.name = 'first';

      var item2 = WithNitriteId();
      item2.name = 'second';

      await repo.insert([item1, item2]);

      var cursor = await repo.find();
      await for (var withNitriteId in cursor) {
        expect(withNitriteId.idField, isNotNull);
      }

      var first = await cursor.first;
      first.name = 'third';

      var id = first.idField;
      await repo.updateOne(first);

      var byId = await repo.getById(id);
      expect(first, byId);
      expect(await repo.size, 2);
    });

    test('Test Set Id During Insert', () async {
      var item = WithNitriteId();
      item.name = 'first';
      item.idField = NitriteId.newId();

      var result = await repo.insert([item]);
      expect(result.getAffectedCount(), 1);

      var first = await (await repo.find()).first;
      expect(first.idField, isNot(item.idField));

      var second = await repo.getById(first.idField);
      expect(second, isNotNull);
      expect(first.idField, second?.idField);
    });

    test('Test Change Id During Update', () async {
      var item = WithNitriteId();
      item.name = 'second';
      var result = await repo.insert([item]);
      var nitriteId = result.first;
      var byId = await repo.getById(nitriteId);
      byId?.idField = NitriteId.newId();

      result = await repo.updateOne(byId!);
      expect(result.getAffectedCount(), 0);
      expect(await repo.size, 1);
    });
  });
}