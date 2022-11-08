import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';

late Nitrite db;
late NitriteCollection collection;
late Document doc1, doc2, doc3;

void setUpLog() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.time}: [${record.level.name}] ${record.loggerName} -'
        ' ${record.message}');
  });
}

Future<void> setUpNitriteTest() async {
  db = await Nitrite.builder()
      .fieldSeparator('.')
      .openOrCreate(username: 'test-user', password: 'test-password');

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
  if (!await collection.isDropped) {
    await collection.close();
  }

  if (!db.isClosed) {
    await db.close();
  }
}

Future<WriteResult> insert() {
  return collection.insert([doc1, doc2, doc3]);
}
