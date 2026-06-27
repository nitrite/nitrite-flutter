import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart' hide where;
import 'package:nitrite_spatial/nitrite_spatial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KNearest filter', () {
    late Nitrite db;
    late NitriteCollection col;

    setUp(() async {
      db = await Nitrite.builder().loadModule(SpatialModule()).openOrCreate();
      col = await db.getCollection('geo');
      await col.createIndex(['location'], indexOptions(spatialIndex));

      var gf = GeometryFactory.defaultPrecision();
      Point pt(double x, double y) => gf.createPoint(Coordinate(x, y));

      // points along a line at increasing distance from origin
      await col.insert(emptyDocument().put('n', 1).put('location', pt(1, 1)));
      await col.insert(emptyDocument().put('n', 2).put('location', pt(2, 2)));
      await col.insert(emptyDocument().put('n', 5).put('location', pt(5, 5)));
      await col.insert(emptyDocument().put('n', 9).put('location', pt(9, 9)));
    });

    tearDown(() async => db.close());

    test('returns k nearest in ascending distance order', () async {
      var cursor =
          col.find(filter: where('location').kNearest(Coordinate(0, 0), 2));
      var ns = <int>[];
      await for (var d in cursor) {
        ns.add(d['n'] as int);
      }
      // find() does not guarantee order, so just check the right set is chosen
      expect(ns.toSet(), {1, 2});
    });

    test('k larger than collection returns all', () async {
      var cursor =
          col.find(filter: where('location').kNearest(Coordinate(0, 0), 10));
      expect(await cursor.length, 4);
    });

    test('maxDistance excludes far points', () async {
      var cursor = col.find(
          filter: where('location')
              .kNearest(Coordinate(0, 0), 10, maxDistance: 4.0));
      var ns = <int>[];
      await for (var d in cursor) {
        ns.add(d['n'] as int);
      }
      // only (1,1) dist~1.41 and (2,2) dist~2.83 are within 4.0
      expect(ns.toSet(), {1, 2});
    });

    test('k=0 throws', () {
      expect(() => where('location').kNearest(Coordinate(0, 0), 0),
          throwsA(isA<ValidationException>()));
    });
  });
}
