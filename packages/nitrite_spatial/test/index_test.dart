import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart' as no2;
import 'package:nitrite/nitrite.dart' hide where;
import 'package:nitrite/src/filters/filter.dart' as filter;
import 'package:nitrite_spatial/nitrite_spatial.dart';
import 'package:nitrite_spatial/src/filter.dart';
import 'package:test/test.dart';

import 'base_test_loader.dart';
import 'test_data.dart';
import 'test_utils.dart';

void main() {
  group(retry: 3, 'Spatial Index Test Suite', () {
    var reader = WKTReader();

    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await tearDownNitriteTest();
    });

    test('Test Intersect', () async {
      var polygon = reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');

      var result = await repository
          .find(filter: where('geometry').intersects(polygon!))
          .toList();
      expect(result.length, 2);
      expect(result, contains(object1));
      expect(result, contains(object2));

      await collection.createIndex(["location"], indexOptions(spatialIndex));
      var cursor = await collection
          .find(
              filter: where('location').intersects(polygon),
              findOptions: orderBy("key", SortOrder.ascending))
          .map((doc) => doc['key']) // equals is not working for geometry
          .toList();
      expect(cursor.length, 2);

      expect(cursor, contains(1));
      expect(cursor, contains(2));
    });

    test('Test Within', () async {
      var polygon = reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');

      var result = await repository
          .find(filter: where('geometry').within(polygon!))
          .toList();
      expect(result.length, 1);
      expect(result, contains(object1));

      await collection.createIndex(["location"], indexOptions(spatialIndex));
      var cursor = await collection
          .find(
              filter: where('location').within(polygon),
              findOptions: orderBy("key", SortOrder.ascending))
          .map((doc) => doc['key']) // equals is not working for geometry
          .toList();
      expect(cursor.length, 1);

      expect(cursor, contains(1));
    });

    test('Test Near Point', () async {
      var point = reader.read('POINT (490 490)') as Point;

      var result = await repository
          .find(filter: where('geometry').near(Center.fromPoint(point), 20.0))
          .toList();
      expect(result.length, 1);
      expect(result, contains(object1));

      await collection.createIndex(["location"], indexOptions(spatialIndex));
      var cursor = await collection
          .find(
              filter: where('location').near(Center.fromPoint(point), 20.0),
              findOptions: orderBy("key", SortOrder.ascending))
          .map((doc) => doc['key']) // equals is not working for geometry
          .toList();
      expect(cursor.length, 1);

      expect(cursor, contains(1));
    });

    test('Test Near Coordinate', () async {
      var point = reader.read('POINT (490 490)') as Point;

      var result = await repository
          .find(
              filter: where('geometry')
                  .near(Center.fromCoordinate(point.getCoordinate()!), 20.0))
          .toList();
      expect(result.length, 1);
      expect(result, contains(object1));

      await collection.createIndex(["location"], indexOptions(spatialIndex));
      var cursor = await collection
          .find(
              filter: where('location')
                  .near(Center.fromCoordinate(point.getCoordinate()!), 20.0),
              findOptions: orderBy("key", SortOrder.ascending))
          .map((doc) => doc['key']) // equals is not working for geometry
          .toList();
      expect(cursor.length, 1);

      expect(cursor, contains(1));
    });

    test('Test Remove Index Entry', () async {
      var search = reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');
      var result = await repository.remove(where('geometry').within(search!));
      expect(result.getAffectedCount(), 1);
    });

    test('Test Update Index', () async {
      var search = reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');
      var update = SpatialData(id: 3, geometry: search);
      var result = await repository.updateOne(update);
      expect(result.getAffectedCount(), 1);
    });

    test('Test Drop All Indexes', () async {
      await repository.dropAllIndices();
      expect(await repository.hasIndex(['geometry']), isFalse);
    });

    test('Test Parse Geometry', () async {
      var db =
          await Nitrite.builder().loadModule(SpatialModule()).openOrCreate();

      var point = reader.read('POINT (500 505)') as Point;
      var document = createDocument('geom', point);

      var collection = await db.getCollection('test');
      await collection.insert(document);
      await collection.createIndex(['geom'], indexOptions(spatialIndex));

      var doc = await collection.find().first;

      var update = doc.clone();
      update['geom'] = reader.read('POINT (0 0)');
      await collection.updateOne(update);
    });

    test('Test And Mixed Query', () async {
      var polygon = reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');

      await collection.createIndex(["location"], indexOptions(spatialIndex));
      await collection.createIndex(["key"]);

      var cursor = collection.find(
        filter: and([
          where('location').intersects(polygon!),
          no2.where('key').eq(2),
        ]),
      );

      var findPlan = await cursor.findPlan;
      expect(findPlan, isNotNull);
      expect(findPlan.indexScanFilter?.filters.length, 1);
      expect(findPlan.indexScanFilter?.filters.first, isA<IntersectsFilter>());
      expect(findPlan.collectionScanFilter, isA<filter.EqualsFilter>());

      var result = await cursor.map((doc) => doc['key']).toList();
      expect(result.length, 1);
      expect(result, contains(2));
    });

    test('Test And Spatial Query', () async {
      var polygon = reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');

      await collection.createIndex(["location"], indexOptions(spatialIndex));

      var cursor = collection.find(
          filter: and([
            where('location').intersects(polygon!),
            where('location').within(polygon),
          ]),
          findOptions: orderBy("key", SortOrder.ascending));

      var result = await cursor.map((doc) => doc['key']).toList();
      expect(result.length, 2);
      expect(result, contains(1));
      expect(result, contains(2));
    });
  });
}
