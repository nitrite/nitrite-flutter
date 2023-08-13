import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group(retry: 3, 'Collection Update Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Update', () async {
      await insert();

      var cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 1);
      await for (var document in cursor) {
        expect(document['lastName'], 'ln1');
      }

      var updateResult = await collection.update(where('firstName').eq('fn1'),
          createDocument('lastName', 'new-last-name'));
      expect(updateResult.getAffectedCount(), 1);

      cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 1);
      await for (var document in cursor) {
        expect(document['lastName'], 'new-last-name');
      }
    });

    test('Test Upsert Without Id', () async {
      await insert();
      var update = createDocument('lastName', 'ln4');

      expect(
          () async => await collection.updateOne(update, insertIfAbsent: false),
          throwsNotIdentifiableException);
    });

    test('Test Upsert', () async {
      await insert();
      expect(await collection.size, 3);

      var update = createDocument('lastName', 'ln4');
      var writeResult =
          await collection.updateOne(update, insertIfAbsent: true);
      expect(writeResult.getAffectedCount(), 1);
      expect(await collection.size, 4);

      var cursor = collection.find(filter: where('lastName').eq('ln4'));
      var document = await cursor.first;
      expect(isSimilarDocument(document, update, ['lastName']), true);
    });

    test('Test Upsert with Options', () async {
      var cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 0);

      var updateResult = await collection.update(where('firstName').eq('fn1'),
          doc1, updateOptions(insertIfAbsent: true));
      expect(updateResult.getAffectedCount(), 1);

      cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 1);
      await for (var document in cursor) {
        expect(
            isSimilarDocument(document, doc1,
                ['firstName', 'lastName', 'birthDay', 'data', 'list', 'body']),
            true);
      }
    });

    test('Test Update Multiple', () async {
      var cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 0);

      await insert();

      var document = createDocument('lastName', 'newLastName1');
      var updateResult =
          await collection.update(where('firstName').eq('fn1').not(), document);
      expect(updateResult.getAffectedCount(), 2);

      cursor = collection.find(filter: where('lastName').eq('newLastName1'));
      expect(await cursor.length, 2);
    });

    test('Test Update with Options Upsert False', () async {
      var cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 0);

      var options = updateOptions(insertIfAbsent: false);
      var updateResult =
          await collection.update(where('firstName').eq('fn1'), doc1, options);
      expect(updateResult.getAffectedCount(), 0);

      cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 0);
    });

    test('Test Update Multiple with Just Once False', () async {
      var cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 0);

      await insert();

      var options = updateOptions(justOnce: false);

      var document = createDocument('lastName', 'newLastName1');
      var updateResult = await collection.update(
          where('firstName').eq('fn1').not(), document, options);
      expect(updateResult.getAffectedCount(), 2);

      cursor = collection.find(filter: where('lastName').eq('newLastName1'));
      expect(await cursor.length, 2);
    });

    test('Test Update Multiple with Just Once True', () async {
      var cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 0);

      await insert();

      var options = updateOptions(justOnce: true);

      var document = createDocument('lastName', 'newLastName1');
      var updateResult = await collection.update(
          where('firstName').eq('fn1').not(), document, options);
      expect(updateResult.getAffectedCount(), 1);

      cursor = collection.find(filter: where('lastName').eq('newLastName1'));
      expect(await cursor.length, 1);
    });

    test('Test Update with New Field', () async {
      await insert();

      var cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 1);
      await for (var document in cursor) {
        expect(document['lastName'], 'ln1');
      }

      var updateResult = await collection.update(where('firstName').eq('fn1'),
          createDocument('new-value', 'new-value-value'));
      expect(updateResult.getAffectedCount(), 1);

      cursor = collection.find(filter: where('firstName').eq('fn1'));
      expect(await cursor.length, 1);
      await for (var document in cursor) {
        expect(document['new-value'], 'new-value-value');
      }
    });

    test('Test Update Invalid Filter', () async {
      await insert();

      var cursor = collection.find(filter: where('lastName').eq('ln1'));
      expect(await cursor.length, 1);

      await for (var document in cursor) {
        expect(document['firstName'], 'fn1');
      }

      var updateResult = await collection.update(
          where('some-value').eq('some-value'),
          createDocument("lastName", "new-last-name"));
      expect(updateResult.getAffectedCount(), 0);
    });

    test('Test Update After Attribute Removal', () async {
      var col = await db.getCollection('test_updateAfterAttributeRemoval');
      await col.remove(all);

      var doc = createDocument("id", "test-1").put("group", "groupA");
      var result = await col.insert(doc);
      expect(result.getAffectedCount(), 1);

      var savedDoc1 = await (col.find()).first;
      expect(savedDoc1, isNotNull);

      var clonedDoc1 = savedDoc1.clone();
      expect(savedDoc1, clonedDoc1);

      clonedDoc1['group'] = null;
      result = await col.updateOne(clonedDoc1);
      expect(result.getAffectedCount(), 1);

      var cursor = col.find();
      var savedDoc2 = await cursor.first;
      expect(savedDoc2, isNotNull);
      expect(savedDoc2['group'], isNull);
    });

    test('Test Update without Id', () async {
      var collection = await db.getCollection('test');
      var document = createDocument('test', 'test123');
      expect(() async => await collection.updateOne(document),
          throwsNotIdentifiableException);
    });

    test('Test Remove without Id', () async {
      var collection = await db.getCollection('test');
      var document = createDocument('test', 'test123');
      expect(() async => await collection.removeOne(document),
          throwsNotIdentifiableException);
    });

    test('Test Register Listener After Drop', () async {
      var collection = await db.getCollection('test');
      await collection.drop();
      expect(() => collection.subscribe((_) => fail('Should not happen')),
          throwsNitriteIOException);
    });

    test('Test Register Listener After Close', () async {
      var collection = await db.getCollection('test');
      await collection.close();
      expect(() => collection.subscribe((_) => fail('Should not happen')),
          throwsNitriteIOException);
    });

    test('Test Unique Contraint in Update', () async {
      var doc1 = createDocument("id", "test-1").put("fruit", "Apple");
      var doc2 = createDocument("id", "test-2").put("fruit", "Ôrange");

      var collection = await db.getCollection('test');
      await collection.insertMany([doc1, doc2]);

      await collection.createIndex(['fruit']);
      var cursor = collection.find(filter: where('fruit').eq('Apple'));
      expect(await cursor.length, 1);

      cursor = collection.find(filter: where('id').eq('test-2'));
      var doc3 = await cursor.first;

      doc3['fruit'] = 'Apple';
      expect(() async => await collection.updateOne(doc3),
          throwsUniqueConstraintException);
    });
  });
}
