// Verifies the Hive-backed nitrite runs entirely inside a background isolate
// (the "heavy DB work off the UI thread" use case).
// Run: dart run tool/verify_isolate.dart
import 'dart:io';
import 'dart:isolate';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';

Future<int> _work(String path) async {
  var module = HiveModule.withConfig().path(path).build();
  var db = await Nitrite.builder().loadModule(module).openOrCreate();
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
  var dir = Directory.systemTemp.createTempSync('nitrite_iso_');
  try {
    // Open + populate + query a persistent DB entirely on a background isolate.
    var count = await Isolate.run(() => _work('${dir.path}/db'));
    if (count != 50) {
      stderr.writeln('FAIL: expected 50, got $count');
      exit(1);
    }
    print('ok: hive nitrite ran in background isolate, eq(3) == $count');

    // Reopen on the main isolate: data written by the background isolate persists.
    var module = HiveModule.withConfig().path('${dir.path}/db').build();
    var db = await Nitrite.builder().loadModule(module).openOrCreate();
    var col = await db.getCollection('c');
    var total = await col.find().count();
    await db.close();
    if (total != 500) {
      stderr.writeln('FAIL: expected 500 after reopen, got $total');
      exit(1);
    }
    print('ok: data persisted across isolate boundary, total == $total');
    print('HIVE ISOLATE CHECK PASSED');
  } finally {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
