// Verifies nitrite (in-memory) runs entirely inside a background isolate.
// Run: dart run tool/verify_isolate.dart
import 'dart:io';
import 'dart:isolate';

import 'package:nitrite/nitrite.dart';

Future<int> _work() async {
  var db = await Nitrite.builder().openOrCreate();
  var col = await db.getCollection('c');
  await col.createIndex(['k'], indexOptions(IndexType.nonUnique));
  for (var i = 0; i < 500; i++) {
    await col.insert(emptyDocument().put('k', i % 10).put('n', i));
  }
  var count = await col.find(filter: where('k').eq(3)).count();
  await db.close();
  return count;
}

Future<void> main() async {
  // Run the whole nitrite workload on a background isolate.
  var count = await Isolate.run(_work);
  if (count != 50) {
    stderr.writeln('FAIL: expected 50, got $count');
    exit(1);
  }
  print('ok: nitrite ran in background isolate, eq(3) count == $count');
  print('ISOLATE CHECK PASSED');
}
