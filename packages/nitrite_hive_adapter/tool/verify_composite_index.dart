// Standalone verification of the composite-key non-unique index on the
// persistent Hive store. Run with: dart run tool/verify_composite_index.dart
import 'dart:io';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';

Future<Nitrite> _open(String path) {
  var module = HiveModule.withConfig().path(path).build();
  return Nitrite.builder().loadModule(module).openOrCreate();
}

void check(bool cond, String msg) {
  if (!cond) {
    stderr.writeln('FAIL: $msg');
    exit(1);
  }
  print('ok: $msg');
}

Future<void> main() async {
  var dir = Directory.systemTemp.createTempSync('nitrite_composite_');
  var path = '${dir.path}/db';
  try {
    var db = await _open(path);
    var col = await db.getCollection('c');
    await col.createIndex(['acct'], indexOptions(IndexType.nonUnique));

    // low-cardinality field: 200 docs across 4 acct values
    for (var i = 0; i < 200; i++) {
      await col.insert(
          emptyDocument().put('acct', i % 4).put('n', i).put('seq', i));
    }

    // equality
    var c0 = await col.find(filter: where('acct').eq(0)).count();
    check(c0 == 50, 'eq(0) count == 50 (got $c0)');

    // range across composite values
    var rng = await col.find(filter: where('acct').between(1, 2)).length;
    check(rng == 100, 'between(1,2) length == 100 (got $rng)');

    // in filter
    var inC = await col.find(filter: where('acct').within([0, 3])).length;
    check(inC == 100, 'within([0,3]) length == 100 (got $inC)');

    // descending sort over indexed field
    var seqs = <int>[];
    await for (var d in col.find(
        filter: where('acct').gte(0),
        findOptions: orderBy('acct', SortOrder.descending))) {
      seqs.add(d['acct'] as int);
    }
    check(seqs.length == 200, 'sorted scan length 200 (got ${seqs.length})');
    check(seqs.first == 3 && seqs.last == 0, 'desc sort 3..0');

    // remove and re-check
    await col.remove(where('n').eq(0));
    var c0b = await col.find(filter: where('acct').eq(0)).count();
    check(c0b == 49, 'after remove eq(0) == 49 (got $c0b)');

    await db.close();

    // reopen: index must persist and still return correct results
    var db2 = await _open(path);
    var col2 = await db2.getCollection('c');
    var c0c = await col2.find(filter: where('acct').eq(0)).count();
    check(c0c == 49, 'after reopen eq(0) == 49 (got $c0c)');
    var total = await col2.find().count();
    check(total == 199, 'after reopen total == 199 (got $total)');
    await db2.close();

    // unique index branch still works
    var db3 = await _open('${dir.path}/db2');
    var u = await db3.getCollection('u');
    await u.createIndex(['email']); // unique by default
    await u.insert(emptyDocument().put('email', 'a@x.com').put('n', 1));
    await u.insert(emptyDocument().put('email', 'b@x.com').put('n', 2));
    var uc = await u.find(filter: where('email').eq('a@x.com')).count();
    check(uc == 1, 'unique eq count == 1 (got $uc)');
    var dup = false;
    try {
      await u.insert(emptyDocument().put('email', 'a@x.com').put('n', 3));
    } on UniqueConstraintException {
      dup = true;
    }
    check(dup, 'unique constraint enforced on duplicate');

    // multikey (iterable) non-unique index
    var m = await db3.getCollection('m');
    await m.createIndex(['tags'], indexOptions(IndexType.nonUnique));
    await m.insert(emptyDocument().put('tags', ['x', 'y']).put('n', 1));
    await m.insert(emptyDocument().put('tags', ['y', 'z']).put('n', 2));
    var ym = await m.find(filter: where('tags').eq('y')).length;
    check(ym == 2, 'multikey eq(y) length == 2 (got $ym)');
    var xm = await m.find(filter: where('tags').eq('x')).length;
    check(xm == 1, 'multikey eq(x) length == 1 (got $xm)');
    await db3.close();

    // write-throughput sanity: bulk load a low-cardinality field
    var db4 = await _open('${dir.path}/db3');
    var big = await db4.getCollection('big');
    await big.createIndex(['folder'], indexOptions(IndexType.nonUnique));
    var sw = Stopwatch()..start();
    for (var i = 0; i < 3000; i++) {
      await big.insert(emptyDocument().put('folder', i % 5).put('n', i));
    }
    sw.stop();
    var bc = await big.find(filter: where('folder').eq(2)).count();
    check(bc == 600, 'bulk eq(2) == 600 (got $bc)');
    print('bulk-load 3000 low-cardinality inserts: ${sw.elapsedMilliseconds} ms');
    await db4.close();

    // compound non-unique composite index (first field low-cardinality)
    var db5 = await _open('${dir.path}/db4');
    var cc = await db5.getCollection('cc');
    await cc.createIndex(['dept', 'age'], indexOptions(IndexType.nonUnique));
    for (var i = 0; i < 120; i++) {
      await cc.insert(emptyDocument()
          .put('dept', i % 3)
          .put('age', 20 + (i % 4))
          .put('n', i));
    }
    // eq on first field
    var d1 = await cc.find(filter: where('dept').eq(1)).count();
    check(d1 == 40, 'compound eq(dept=1) == 40 (got $d1)');
    // eq on both fields
    var d1a = await cc
        .find(filter: where('dept').eq(1).and(where('age').eq(20)))
        .count();
    check(d1a == 10, 'compound eq(dept=1,age=20) == 10 (got $d1a)');
    // range on second field within first
    var d1r = await cc
        .find(filter: where('dept').eq(0).and(where('age').gte(22)))
        .length;
    check(d1r == 20, 'compound dept=0 & age>=22 == 20 (got $d1r)');
    await db5.close();

    // reopen: compound composite index persists
    var db6 = await _open('${dir.path}/db4');
    var cc2 = await db6.getCollection('cc');
    var d1b = await cc2
        .find(filter: where('dept').eq(1).and(where('age').eq(20)))
        .count();
    check(d1b == 10, 'compound after reopen == 10 (got $d1b)');
    await db6.close();

    // unique compound index (composite + prefix probe)
    var db7 = await _open('${dir.path}/db5');
    var ucol = await db7.getCollection('uc');
    await ucol.createIndex(['first', 'last']); // unique by default
    await ucol.insert(emptyDocument().put('first', 'a').put('last', 'b'));
    await ucol.insert(emptyDocument().put('first', 'a').put('last', 'c')); // ok
    var ucViolation = false;
    try {
      await ucol.insert(emptyDocument().put('first', 'a').put('last', 'b'));
    } on UniqueConstraintException {
      ucViolation = true;
    }
    check(ucViolation, 'unique compound rejects duplicate (a,b)');
    var ucq = await ucol
        .find(filter: where('first').eq('a').and(where('last').eq('c')))
        .count();
    check(ucq == 1, 'unique compound eq(a,c) == 1 (got $ucq)');
    await db7.close();

    print('ALL COMPOSITE INDEX CHECKS PASSED');
  } finally {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
