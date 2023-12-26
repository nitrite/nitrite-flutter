import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart' as no2;
import 'package:nitrite_spatial/nitrite_spatial.dart';
import 'package:test/test.dart';

import 'base_test_loader.dart';
import 'test_utils.dart';

void main() {
  group(retry: 0, 'Spatial Index Negative Test Suite', () {
    var reader = WKTReader();

    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await tearDownNitriteTest();
    });

    test('Test No Index', () async {
      var polygon = reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');

      var error = false;
      try {
        var cursor = await collection
            .find(filter: where('location').intersects(polygon!))
            .map((doc) => doc['key']) // equals is not working for geometry
            .toList();
        expect(cursor.length, 2);
      } catch (e) {
        error = true;
        expect(e, isA<no2.FilterException>());
      }

      expect(error, true);
    });

    test('Test Index Exists', () async {
      var error = false;
      try {
        await collection
            .createIndex(["location"], no2.indexOptions(spatialIndex));
        await collection
            .createIndex(["location"], no2.indexOptions(spatialIndex));
      } catch (e) {
        error = true;
        expect(e, isA<no2.IndexingException>());
      }

      expect(error, true);
    });

    test('Test Drop Index', () async {
      await repository.dropIndex(['geometry']);

      var search = reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');
      var error = false;
      try {
        var cursor = await repository
            .find(filter: where('geometry').within(search!))
            .toList();
        expect(cursor.length, 1);
      } catch (e) {
        error = true;
        expect(e, isA<no2.FilterException>());
      }

      expect(error, true);
    });

    test('Test Find Equal', () async {
      var search = reader.read('POINT (500 505)') as Point;
      var error = false;
      try {
        var cursor = await repository
            .find(filter: no2.where('geometry').eq(search))
            .toList();
        expect(cursor.length, 2);
      } catch (e) {
        error = true;
        expect(e, isA<no2.FilterException>());
      }

      expect(error, true);
    });

    test('Test Compound Index', () async {
      var error = false;
      try {
        await collection
            .createIndex(["location", "key"], no2.indexOptions(spatialIndex));
      } catch (e) {
        error = true;
        expect(e, isA<no2.IndexingException>());
      }

      expect(error, true);
    });

    test('Test Multiple Spatial Index on Multiple Fields', () async {
      var polygon = reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');

      await collection
          .createIndex(["location"], no2.indexOptions(spatialIndex));
      await collection.createIndex(["area"], no2.indexOptions(spatialIndex));

      var error = false;
      try {
        var cursor = await collection
            .find(
                filter: no2.and([
                  where('location').intersects(polygon!),
                  where('area').within(polygon),
                ]),
                findOptions: no2.orderBy("key", no2.SortOrder.ascending))
            .map((doc) => doc['key']) // equals is not working for geometry
            .toList();
        expect(cursor.length, 0);
      } catch (e) {
        error = true;
        expect(e, isA<no2.FilterException>());
      }

      expect(error, true);
    });
  });
}
