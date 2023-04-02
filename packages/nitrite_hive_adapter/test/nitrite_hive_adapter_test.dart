// ignore_for_file: unused_import

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/splay_tree_extensions.dart';
import 'package:nitrite_hive_adapter/src/adapters/document_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/nitrite_id_adapter.dart';
import 'package:nitrite_hive_adapter/src/store/box_map.dart';
import 'package:nitrite_hive_adapter/src/store/hive_module.dart';
import 'package:nitrite_hive_adapter/src/store/hive_store.dart';
import 'package:nitrite_hive_adapter/src/store/hive_utils.dart';
import 'package:nitrite_hive_adapter/src/store/key_encoder.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Demo test', () {
    test('First Test', () async {
      var dbPath = '${Directory.current.path}/db';
      //
      // var storeModule =
      //     HiveModule.withConfig().crashRecovery(true).path(dbPath).build();
      //
      // var builder = await Nitrite.builder().loadModule(storeModule);
      //
      // var db = await builder
      //     .fieldSeparator('.')
      //     .openOrCreate(username: 'test', password: 'test');
      //
      // print('Path - $dbPath');
      //
      // var document = createDocument('first', DateTime.now().toIso8601String())
      //     .put('second', createDocument('array', [0, 1, 2]))
      //     .put('third', null)
      //     .put('fourth', NitriteId.newId())
      //     .put('fifth', emptyDocument())
      //     .put('sixth', 12.5);
      //
      // var col = await db.getCollection('test');
      // var result = await col.insert([document]);
      // print(result.getAffectedCount());

      // Hive.init(dbPath);
      // var storeModule =
      //     HiveModule.withConfig().crashRecovery(true).path(dbPath).build();
      //
      // var store = storeModule.plugins.toList()[0] as HiveStore;
      // await store.initialize(NitriteConfig());
      // await store.openOrCreate();
      //
      // var boxMap = await store.openBoxMap('test');
      // var splayTreeMap = SplayTreeMap<int, int>(nitriteKeyComparator);
      //
      // for (var i = 0; i < 10; i = i + 2) {
      //   await boxMap.put(i, i);
      //   splayTreeMap[i] = i;
      // }
      //
      // print(await boxMap.floorKey(5));
      // print(splayTreeMap.floorKey(5));
      //
      // var dbFile = File(dbPath);
      // await dbFile.delete(recursive: true);
    });
  });
}
