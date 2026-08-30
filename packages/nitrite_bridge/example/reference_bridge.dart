// A bridge you can point the dbinspect conformance suite at.
//
// Pure Dart on Nitrite's in-memory store, so it runs with no device, no
// emulator and no Flutter SDK.
//
//   dart run example/reference_bridge.dart
//   dart run <dbinspect>/conformance/bin/dbinspect_conformance.dart 127.0.0.1:<port> <code>
//
// It prints one line of JSON — `{"host":…,"port":…,"code":…}` — before the
// bridge's own pairing banner, so a script does not have to parse the banner.
// Then it stays up until it is killed.
//
// The adapter is constructed with **no options**, because that is what
// `THREAT-MODEL.md` §7 criterion 10 is about, and it is what makes criterion 9
// meaningful here: `regex` must be absent from `filterOps` and refused.
// `--permissive` opens the gates and is the suite's negative control.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite_bridge/nitrite_bridge.dart';

Future<Nitrite> openFixture() async {
  final db = await Nitrite.builder().openOrCreate();

  final users = await db.getCollection('users');
  // One blob larger than the 64 KB inline ceiling, so the suite has a truncated
  // value to check rather than skipping that shape.
  final random = Random(7);
  final avatar = Uint8List.fromList(
      [for (var i = 0; i < 100 * 1024; i++) random.nextInt(256)]);

  await users.insertMany([
    for (var i = 0; i < 250; i++)
      createDocument('name', i == 3 ? 'user with a ünicode name' : 'user $i')
        ..put('age', i.isEven ? 20 + (i % 50) : null)
        ..put('score', i / 3)
        ..put('avatar', i == 0 ? avatar : null)
  ]);

  // An empty store, so a driver that pages the first store it is told about
  // cannot pass every paging check against nothing.
  await (await db.getCollection('empty_collection')).size;
  return db;
}

Future<void> main(List<String> arguments) async {
  final permissive = arguments.contains('--permissive');

  final db = await openFixture();
  final bridge = await startBridge(
    appName: 'reference_bridge',
    adapters: [
      NitriteAdapter(
        db,
        id: 'nitrite-main',
        displayName: 'Nitrite (memory)',
        allowRegex: permissive,
        allowWrite: permissive,
        allowSnapshot: permissive,
      ),
    ],
  );
  if (bridge == null) {
    stderr
        .writeln('this build does not contain the bridge — see bridgeEnabled');
    exit(70); // EX_SOFTWARE
  }

  stdout.writeln(jsonEncode({
    'host': bridge.address.address,
    'port': bridge.port,
    'code': bridge.pairingCode.value,
  }));
  stdout.writeln(bridge.banner);
  if (permissive) {
    stdout.writeln('--permissive: every capability gate is open. This is the '
        'conformance suite\'s negative control, not an example to copy.');
  }

  // Nothing to do but stay up. The suite kills the process when it is finished,
  // and it has to be a fresh process for the next run anyway — the last phase
  // closes pairing for good.
  await Completer<void>().future;
}
