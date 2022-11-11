import 'package:faker/faker.dart';
import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'base_collection_test.dart';

void main() {
  group("Custom Field Separator Test Suite", () {
    late Nitrite db;
    late NitriteCollection collection;

    setUp(() async {
      setUpLog();
      db = await Nitrite.builder().fieldSeparator(':').openOrCreate();
      collection = await db.getCollection("test");
    });

    tearDown(() async {
      NitriteConfig.fieldSeparator = '.';
      if (!db.isClosed) {
        await db.close();
      }
    });

    test("Test Field Separator", () async {
      expect(NitriteConfig.fieldSeparator, equals(':'));
    });

    test("Test Find By Embedded Field", () async {
      var faker = Faker();

      for (var i = 0; i < 10; i++) {
        var doc = emptyDocument()
          ..put('empId', faker.randomGenerator.integer(100))
          ..put(
              'employeeNote',
              emptyDocument()
                ..put('noteId', faker.guid.toString())
                ..put('text', faker.lorem.sentence()));

        await collection.insert([doc]);
      }

      var cursor =
          await collection.find(filter: where('employeeNote.text').notEq(null));
      expect(await cursor.toList(), isEmpty);

      cursor =
          await collection.find(filter: where('employeeNote:text').notEq(null));
      expect(await cursor.toList(), isNotEmpty);
    });
  });
}
