import 'dart:io';

import 'package:faker/faker.dart';
import 'package:logging/logging.dart';

void setUpLog() {
  Logger.root.level = Level.SEVERE;
  Logger.root.onRecord.listen((record) {
    print('${record.time}: [${record.level.name}] ${record.loggerName} -'
        ' ${record.message}');
    if (record.error != null) {
      print('ERROR: ${record.error}');
    }
  });
}

String getRandomTempDbPath() {
  var faker = Faker();
  return '${Directory.current.path}/db/${faker.guid.guid()}';
}

Future<void> deleteDb(String dbPath) async {
  var dbFile = Directory(dbPath);
  await dbFile.delete(recursive: true);
}
