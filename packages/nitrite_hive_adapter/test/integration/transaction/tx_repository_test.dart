import 'package:flutter_test/flutter_test.dart';
import 'package:nitrite/nitrite.dart';

import '../repository/base_object_repository_test_loader.dart';
import '../repository/data/test_objects.dart';

void main() {
  group('Transaction Repository Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Commit Insert', () async {
      var repository = await db.getRepository<TxData>();
      var session = db.createSession();
      var tx = await session.beginTransaction();

      var data = TxData()
        ..name = 'John'
        ..id = 1;

      var txRepo = await tx.getRepository<TxData>();
      await txRepo.insert([data]);

      var txCursor = await txRepo.find(filter: where('name').eq('John'));
      expect(await txCursor.length, 1);

      var cursor = await repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 0);

      await tx.commit();

      cursor = await repository.find(filter: where('name').eq('John'));
      expect(await cursor.length, 1);
    });
  });
}
