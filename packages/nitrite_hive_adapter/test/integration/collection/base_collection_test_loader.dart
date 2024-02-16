import 'dart:io';

import 'package:faker/faker.dart';
import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';
import 'package:test/expect.dart';

late Nitrite db;
late NitriteCollection collection;
late Document doc1, doc2, doc3;
late String dbPath;
late Faker faker;

void setUpLog() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.time}: [${record.level.name}] ${record.loggerName} -'
        ' ${record.message}');
    if (record.error != null) {
      print('ERROR: ${record.error}');
    }
  });
}

Future<void> setUpNitriteTest() async {
  faker = Faker();
  dbPath = '${Directory.current.path}/db/${faker.guid.guid()}';

  var storeModule =
      HiveModule.withConfig().crashRecovery(true).path(dbPath).build();

  db = await Nitrite.builder()
      .loadModule(storeModule)
      .fieldSeparator('.')
      .openOrCreate(username: 'test', password: 'test');

  doc1 = emptyDocument()
      .put("firstName", "fn1")
      .put("lastName", "ln1")
      .put("birthDay", DateTime.parse("2012-07-01T16:02:48.440Z"))
      .put("data", [1, 2, 3]).put("list", ["one", "two", "three"]).put(
          "body", "a quick brown fox jump over the lazy dog");

  doc2 = emptyDocument()
      .put("firstName", "fn2")
      .put("lastName", "ln2")
      .put("birthDay", DateTime.parse("2010-06-12T16:02:48.440Z"))
      .put("data", [3, 4, 3]).put("list", ["three", "four", "five"]).put(
          "body", "quick hello world from nitrite");

  doc3 = emptyDocument()
      .put("firstName", "fn3")
      .put("lastName", "ln2")
      .put("birthDay", DateTime.parse("2014-04-17T16:02:48.440Z"))
      .put("data", [9, 4, 8]).put(
          "body",
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nunc mi, '
              'mattis ullamcorper dignissim vitae, condimentum non lorem.');

  collection = await db.getCollection('test');
  await collection.remove(all);
}

Future<void> cleanUp() async {
  if (!collection.isDropped) {
    await collection.close();
  }

  if (!db.isClosed) {
    await db.close();
  }

  var dbFile = File(dbPath);
  await dbFile.delete(recursive: true);
}

Future<WriteResult> insert() async {
  var result = await collection.insertMany([doc1, doc2, doc3]);

  expect(await collection.size, 3);
  return result;
}
