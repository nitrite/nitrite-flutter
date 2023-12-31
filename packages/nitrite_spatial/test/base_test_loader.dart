import 'package:dart_jts/dart_jts.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';
import 'package:nitrite_spatial/nitrite_spatial.dart';

import 'test_data.dart';
import 'test_utils.dart';

late Nitrite db;
late String dbPath;
late NitriteCollection collection;
late ObjectRepository<SpatialData> repository;
late SpatialData object1, object2, object3;
late Document doc1, doc2, doc3, doc4;

Future<void> setUpNitriteTest() async {
  dbPath = getRandomTempDbPath();
  db = await _createDb(dbPath);

  collection = await db.getCollection('spatial_data');
  repository = await db.getRepository<SpatialData>();

  await _insertDocuments();
  await _insertObjects();
}

Future<void> tearDownNitriteTest() async {
  await db.close();
  await deleteDb(dbPath);
}

Document trimMeta(Document document) {
  document.remove(docId);
  document.remove(docRevision);
  document.remove(docModified);
  document.remove(docSource);
  return document;
}

Future<Nitrite> _createDb(String dbPath, [String? user, String? password]) {
  var storeModule = HiveModule.withConfig()
      .path(dbPath)
      .addTypeAdapter(GeometryAdapter())
      .build();

  return Nitrite.builder()
      .loadModule(storeModule)
      .registerEntityConverter(SpatialDataConverter())
      .loadModule(SpatialModule())
      .openOrCreate(username: user, password: password);
}

Future<void> _insertObjects() async {
  var reader = WKTReader();

  object1 = SpatialData(id: 1, geometry: reader.read('POINT (500 505)'));
  object2 = SpatialData(
      id: 2, geometry: reader.read('LINESTRING (550 551, 525 512, 565 566)'));
  object3 = SpatialData(
      id: 3,
      geometry: reader
          .read('POLYGON ((550 521, 580 540, 570 564, 512 566, 550 521))'));

  await repository.insert(object1);
  await repository.insert(object2);
  await repository.insert(object3);
}

Future<void> _insertDocuments() async {
  var reader = WKTReader();

  doc1 =
      createDocument('key', 1).put('location', reader.read('POINT (500 505)'));
  doc2 = createDocument('key', 2)
      .put('location', reader.read('LINESTRING (550 551, 525 512, 565 566)'));
  doc3 = createDocument('key', 3).put('location',
      reader.read('POLYGON ((550 521, 580 540, 570 564, 512 566, 550 521))'));
  doc4 = createDocument('key', 4);

  await collection.insert(doc1);
  await collection.insert(doc2);
  await collection.insert(doc3);
  await collection.insert(doc4);
}
