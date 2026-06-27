import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart' hide where;
import 'package:nitrite_spatial/nitrite_spatial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoNear filter', () {
    late Nitrite db;
    late NitriteCollection col;

    setUp(() async {
      db = await Nitrite.builder()
          .loadModule(SpatialModule())
          .openOrCreate();
      col = await db.getCollection('geo');
      await col.createIndex(['location'], indexOptions(spatialIndex));

      // Geometry uses x=lon, y=lat
      var gf = GeometryFactory.defaultPrecision();
      Point pt(double lat, double lon) =>
          gf.createPoint(Coordinate(lon, lat));

      // Minneapolis ~ (45.0, -93.265)
      await col.insert(emptyDocument()
          .put('city', 'mpls')
          .put('location', pt(45.0, -93.265)));
      // ~5 km north
      await col.insert(emptyDocument()
          .put('city', 'near')
          .put('location', pt(45.045, -93.265)));
      // Los Angeles, far away
      await col.insert(
          emptyDocument().put('city', 'la').put('location', pt(34.0, -118.0)));
    });

    tearDown(() async => db.close());

    test('finds points within geodesic distance, excludes far ones', () async {
      var center = GeoPoint(45.0, -93.265);
      var cursor = col.find(filter: where('location').geoNear(center, 10000));
      var cities = <String>[];
      await for (var d in cursor) {
        cities.add(d['city'] as String);
      }
      expect(cities..sort(), ['mpls', 'near']);
    });

    test('tight radius matches only the exact point', () async {
      var center = GeoPoint(45.0, -93.265);
      var cursor = col.find(filter: where('location').geoNear(center, 100));
      var cities = <String>[];
      await for (var d in cursor) {
        cities.add(d['city'] as String);
      }
      expect(cities, ['mpls']);
    });

    test('GeoPoint validates ranges', () {
      expect(() => GeoPoint(91, 0), throwsA(isA<ValidationException>()));
      expect(() => GeoPoint(0, 181), throwsA(isA<ValidationException>()));
    });
  });
}
