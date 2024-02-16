import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'collection/base_collection_test_loader.dart';

void main() {
  final Logger _log = Logger('StressTest Suite');

  group(retry: 3, 'Document Index Write Test Suite', () {
    setUp(() async {
      // Additional setup goes here.
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test 300000 Insertions with Indexes', () async {
      var collection = await db.getCollection('test300000');
      await collection.createIndex(['name'], indexOptions(IndexType.nonUnique));
      await collection.createIndex(['age'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['address'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['email'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['phone'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['dateOfBirth'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['company'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['balance'], indexOptions(IndexType.nonUnique));
      await collection
          .createIndex(['isActive'], indexOptions(IndexType.nonUnique));
      await collection.createIndex(['guid']);
      await collection
          .createIndex(['index'], indexOptions(IndexType.nonUnique));

      var uuid = Uuid();
      _log.info('Inserting 300000 documents');
      for (var i = 0; i < 10; i++) {
        var stopwatch = Stopwatch()..start();
        for (var j = 0; j < 30000; j++) {
          await collection.insert(documentFromMap({
            'name': 'name $j',
            'age': j,
            'address': 'address $j',
            'email': 'email $j',
            'phone': 'phone $j',
            'dateOfBirth': DateTime.now(),
            'company': 'company $j',
            'balance': j,
            'isActive': j % 2 == 0,
            'guid': uuid.v4(),
            'index': j
          }));
        }
        stopwatch.stop();
        _log.info(
            'Insertion of 30000 documents took ${stopwatch.elapsedMilliseconds} ms');
      }

      if (await db.hasUnsavedChanges) {
        await db.commit();
      }

      var updatedDocument = createDocument('unrelatedField', 'unrelatedValue');
      var stopwatch = Stopwatch()..start();
      await collection.update(where('balance').eq(200000), updatedDocument,
          updateOptions(insertIfAbsent: false));
      stopwatch.stop();

      _log.info(
          'Update of 1 documents took ${stopwatch.elapsedMilliseconds} ms');
    }, timeout: Timeout(Duration(minutes: 30)), skip: true);
  });
}
