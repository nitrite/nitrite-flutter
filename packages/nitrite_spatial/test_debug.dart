import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_spatial/nitrite_spatial.dart' as spatial;

void main() async {
  print('Testing filter apply directly...');
  
  var reader = WKTReader();
  var polygon = reader.read('POLYGON ((490 490, 536 490, 536 515, 490 515, 490 490))');
  var point = reader.read('POINT (500 505)');
  
  // Create a document with the geometry
  var doc = createDocument('geometry', point);
  
  // Create the filter
  var filter = spatial.where('geometry').intersects(polygon!);
  
  // Apply the filter
  var result = filter.apply(doc);
  
  print('Filter result: $result');
  print('Expected: true');
}
