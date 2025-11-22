import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart' hide where;
import 'package:nitrite_spatial/nitrite_spatial.dart';
import 'package:test/test.dart';

import 'base_test_loader.dart';
import 'test_utils.dart';

void main() {
  group(retry: 3, 'Spatial Intersects False Positive Test Suite', () {
    var reader = WKTReader();

    setUp(() async {
      setUpLog();
      await setUpNitriteTest();
    });

    tearDown(() async {
      await tearDownNitriteTest();
    });

    test('Test Intersects - Polygon and MultiPoint with overlapping bounding boxes but no intersection', () async {
      // This is the test case from the issue report
      // The polygon and multipoint have overlapping bounding boxes
      // but the geometries themselves do not intersect
      var polygon = reader.read('POLYGON ((40486.563 45036.319, 40084.108 44545.927, 39496.171 44938.774, 39889.018 45526.712, 40486.563 45036.319))') as Polygon;
      var multipoint = reader.read('MULTIPOINT ((40933.744 45423.275), (40395.332 45612.623), (40574.536 45576.665))') as MultiPoint;

      // Insert the multipoint into the collection
      final doc = createDocument("geometry", multipoint);
      await collection.insert([doc]);

      // Create spatial index
      await collection.createIndex(["geometry"], indexOptions(spatialIndex));

      // Query for geometries that intersect the polygon
      final result = await collection
          .find(filter: where('geometry').intersects(polygon))
          .toList();

      // The multipoint does not intersect the polygon, so result should be empty
      expect(result.length, 0, reason: 'MultiPoint does not intersect Polygon, should return no results');
    });

    test('Test Intersects - Polygon and Point inside bounding box but outside geometry', () async {
      // Create a polygon and a point that is inside the bounding box
      // but outside the actual polygon
      var polygon = reader.read('POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))') as Polygon;
      var pointOutside = reader.read('POINT (15 15)') as Point; // Outside bounding box
      var pointInsideBBoxButOutsidePolygon = reader.read('POINT (12 5)') as Point; // Would be in bbox if expanded

      // Actually, let's use a non-convex polygon to make this clearer
      // L-shaped polygon
      var lShapedPolygon = reader.read('POLYGON ((0 0, 10 0, 10 5, 5 5, 5 10, 0 10, 0 0))') as Polygon;
      var pointInBBoxButOutsidePolygon = reader.read('POINT (7 7)') as Point; // In bbox but outside L-shape

      // Insert the point
      final doc = createDocument("geometry", pointInBBoxButOutsidePolygon);
      await collection.insert([doc]);

      // Create spatial index
      await collection.createIndex(["geometry"], indexOptions(spatialIndex));

      // Query for geometries that intersect the L-shaped polygon
      final result = await collection
          .find(filter: where('geometry').intersects(lShapedPolygon))
          .toList();

      // The point is inside the bounding box but outside the polygon
      expect(result.length, 0, reason: 'Point is in bounding box but outside polygon geometry');
    });

    test('Test Intersects - Actual intersection should return results', () async {
      // Create geometries that actually intersect
      var polygon = reader.read('POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))') as Polygon;
      var pointInside = reader.read('POINT (5 5)') as Point;
      var lineIntersecting = reader.read('LINESTRING (-5 5, 15 5)') as LineString;

      // Insert the geometries
      await collection.insert([
        createDocument("id", 1).put("geometry", pointInside),
        createDocument("id", 2).put("geometry", lineIntersecting),
      ]);

      // Create spatial index
      await collection.createIndex(["geometry"], indexOptions(spatialIndex));

      // Query for geometries that intersect the polygon
      final result = await collection
          .find(filter: where('geometry').intersects(polygon))
          .toList();

      // Both geometries intersect the polygon
      expect(result.length, 2, reason: 'Point and LineString both intersect the polygon');
    });

    test('Test Within - Point in bounding box but outside geometry', () async {
      // L-shaped polygon
      var lShapedPolygon = reader.read('POLYGON ((0 0, 10 0, 10 5, 5 5, 5 10, 0 10, 0 0))') as Polygon;
      var pointInBBoxButOutsidePolygon = reader.read('POINT (7 7)') as Point;

      // Insert the point
      final doc = createDocument("geometry", pointInBBoxButOutsidePolygon);
      await collection.insert([doc]);

      // Create spatial index
      await collection.createIndex(["geometry"], indexOptions(spatialIndex));

      // Query for geometries within the L-shaped polygon
      final result = await collection
          .find(filter: where('geometry').within(lShapedPolygon))
          .toList();

      // The point is not within the polygon
      expect(result.length, 0, reason: 'Point is in bounding box but not within polygon geometry');
    });
  });
}
