import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_spatial/nitrite_spatial.dart';
import 'package:nitrite_spatial/src/geom_utils.dart';

part 'test_data.no2.dart';

@Entity(indices: [
  Index(fields: ['geometry'], type: spatialIndex),
])
@GenerateConverter()
class SpatialData with _$SpatialDataEntityMixin {
  @Id(fieldName: 'id')
  int? id;
  Geometry? geometry;

  SpatialData({this.id, this.geometry});

  @override
  String toString() {
    return 'SpatialData{id: $id, geometry: $geometry}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          geometryEquals(geometry, other.geometry);

  @override
  int get hashCode => id.hashCode ^ geometry.hashCode;
}
