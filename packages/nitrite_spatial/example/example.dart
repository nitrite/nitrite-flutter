import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_spatial/nitrite_spatial.dart' as sp;
import 'package:nitrite_spatial/nitrite_spatial.dart';

part 'example.no2.dart';

void main() async {
  // create a Nitrite database
  var db = await Nitrite.builder()
      .registerEntityConverter(LocationDataConverter())
      .loadModule(SpatialModule())
      .openOrCreate();

  // create an object repository for LocationData
  var repo = await db.getRepository<LocationData>();

  // create some objects and insert them into the repository
  var reader = WKTReader();
  var object1 = LocationData(id: 1, location: reader.read('POINT (500 505)'));
  var object2 = LocationData(
      id: 2, location: reader.read('LINESTRING (550 551, 525 512, 565 566)'));
  var object3 = LocationData(
      id: 3,
      location: reader
          .read('POLYGON ((550 521, 580 540, 570 564, 512 566, 550 521))'));
  await repo.insertMany([object1, object2, object3]);

  // execute a query
  var cursor = repo.find(
      filter: sp.where('location').intersects(reader
          .read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))')!));

  // print the results
  await cursor.forEach((element) {
    print(element);
  });
}

@Entity(indices: [
  Index(fields: ['location'], type: spatialIndex),
])
@Convertable()
class LocationData with _$LocationDataEntityMixin {
  @Id(fieldName: 'id')
  int? id;
  Geometry? location;

  LocationData({this.id, this.location});

  @override
  String toString() {
    return 'LocationData{id: $id, location: $location}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          geometryEquals(location, other.location);

  @override
  int get hashCode => id.hashCode ^ location.hashCode;
}
