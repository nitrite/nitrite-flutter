import 'package:nitrite/nitrite.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';
import 'base_collection_test_loader.dart';

void main() {
  group('Collection Find Negative Test Suite', () {
    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await cleanUp();
    });

    test('Test Find Filter Invalid Index', () async {
      await insert();
      expect(
          () async =>
              (collection.find(filter: where('data.9').eq(4))).toList(),
          throwsValidationException);
    });

    test('Test Find Options Negative Offset', () async {
      await insert();
      expect(
          () async =>
              (collection.find(findOptions: skipBy(-1).setLimit(1)))
                  .toList(),
          throwsValidationException);
    });

    test('Test Find Options Negative Limit', () async {
      await insert();
      expect(
          () async =>
              (collection.find(findOptions: skipBy(0).setLimit(-1)))
                  .toList(),
          throwsValidationException);
    });

    test('Test Find Invalid Sort', () async {
      await insert();
      expect(
          () async => (collection.find(
                  findOptions: orderBy('data', SortOrder.descending)))
              .toList(),
          throwsInvalidOperationException);
    });

    test('Test Find Text Filter Non Indexed', () async {
      await insert();
      expect(
          () async =>
              (collection.find(filter: where('body').text('Lorem')))
                  .toList(),
          throwsFilterException);
    });

    test('Test Find with Regex Invalid Value', () async {
      await insert();
      expect(
          () async =>
              (collection.find(filter: where('birthDay').regex('hello')))
                  .toList(),
          throwsFilterException);
    });

    test('Test Invalid Projection', () async {
      await insert();
      var cursor = collection.find(
          filter: where('birthDay').lte(DateTime.now()),
          findOptions: orderBy('firstName').setSkip(0).setLimit(3));

      var projection = createDocument('firstName', null).put('lastName', 'ln2');
      expect(() async => await cursor.project(projection).toList(),
          throwsValidationException);
    });
  });
}
