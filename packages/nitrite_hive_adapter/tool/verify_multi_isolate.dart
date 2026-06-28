// Verifies multiple isolates concurrently reading and writing the SAME Hive
// database through a single owner isolate (NitriteIsolate).
// Run: dart run tool/verify_multi_isolate.dart
import 'dart:io';
import 'dart:isolate';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';

void check(bool cond, String msg) {
  if (!cond) {
    stderr.writeln('FAIL: $msg');
    exit(1);
  }
  print('ok: $msg');
}

Future<void> main() async {
  var dir = Directory.systemTemp.createTempSync('nitrite_multi_');
  var path = '${dir.path}/db';
  try {
    // owner isolate holds the one and only handle to the Hive file
    var db = await NitriteIsolate.spawn(() async {
      var module = HiveModule.withConfig().path(path).build();
      return Nitrite.builder().loadModule(module).openOrCreate();
    });

    await db
        .getCollection('c')
        .createIndex(['w'], indexOptions(IndexType.nonUnique));

    // 4 worker isolates each insert 250 docs into the same db, concurrently
    const workers = 4;
    const perWorker = 250;
    await Future.wait([
      for (var w = 0; w < workers; w++)
        Isolate.run(() async {
          var col = db.getCollection('c');
          for (var i = 0; i < perWorker; i++) {
            await col.insert([
              emptyDocument()
                  .put('w', w)
                  .put('i', i)
                  .put('n', w * perWorker + i)
            ]);
          }
          return col.size;
        }),
    ]);

    // all writes are visible and consistent from the main isolate
    var total = await db.getCollection('c').size;
    check(total == workers * perWorker,
        'concurrent inserts total == ${workers * perWorker} (got $total)');

    // concurrent reads from several isolates see each worker's slice
    var counts = await Future.wait([
      for (var w = 0; w < workers; w++)
        Isolate.run(() async {
          var found =
              await db.getCollection('c').find(filter: where('w').eq(w));
          return found.length;
        }),
    ]);
    check(counts.every((c) => c == perWorker),
        'each worker slice has $perWorker docs (got $counts)');

    // concurrent read-modify from multiple isolates
    await Future.wait([
      Isolate.run(() => db.getCollection('c').remove(where('w').eq(0))),
      Isolate.run(() => db
          .getCollection('c')
          .update(where('w').eq(1), emptyDocument().put('tag', 'x'))),
    ]);
    var afterRemove = await db.getCollection('c').size;
    check(afterRemove == (workers - 1) * perWorker,
        'after concurrent remove == ${(workers - 1) * perWorker} (got $afterRemove)');
    var tagged = await db.getCollection('c').find(filter: where('tag').eq('x'));
    check(tagged.length == perWorker,
        'concurrent update tagged $perWorker docs (got ${tagged.length})');

    await db.close();

    // reopen normally: everything the isolates wrote persisted
    var module = HiveModule.withConfig().path(path).build();
    var plain = await Nitrite.builder().loadModule(module).openOrCreate();
    var pc = await (await plain.getCollection('c')).size;
    check(pc == (workers - 1) * perWorker, 'persisted after reopen (got $pc)');
    await plain.close();

    print('ALL MULTI-ISOLATE CHECKS PASSED');
  } finally {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
