import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group(retry: 3, 'Unique Index Self Rewrite Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    // A unique index over an array field visits every element of the array,
    // including a repeated one. The second visit reaches the key the very same
    // document already owns, which is not another document holding it.
    test('Test Repeated Element In One Document Is Not A Violation', () async {
      await collection.createIndex(['tags'], indexOptions(IndexType.unique));

      var doc = createDocument('tags', ['a', 'b', 'a']);
      await collection.insert(doc);

      expect(await collection.size, 1);
      var found = await collection.find(filter: where('tags').eq('a')).toList();
      expect(found.length, 1);
    });

    test('Test Two Documents Sharing A Key Is A Violation', () async {
      await collection.createIndex(['tags'], indexOptions(IndexType.unique));

      await collection.insert(createDocument('tags', ['a', 'b']));
      expect(
        () async => await collection.insert(createDocument('tags', ['c', 'a'])),
        throwsUniqueConstraintException,
      );
    });
  });
}
