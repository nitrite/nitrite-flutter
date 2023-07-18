import 'package:flutter/material.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_demo/models.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

// https://github.com/ivansaul/flutter_todo_app/tree/hive
// https://github.com/MuhammedAmjadK/flutter_todo_app/tree/master
// https://www.youtube.com/watch?v=koVAJis-qIE

@riverpod
Future<Nitrite> db(DbRef ref) async {
  var path = await getApplicationDocumentsDirectory();
  var storeModule =
      HiveModule.withConfig().crashRecovery(true).path('$path/db').build();
  var builder = await Nitrite.builder().loadModule(storeModule);

  var db = await builder
      .fieldSeparator('.')
      .openOrCreate(username: 'demo', password: 'demo123');
  return db;
}

@riverpod
Future<ObjectRepository<Todo>> todoRepositoryProvider(
    TodoRepositoryProviderRef ref) async {
  var db = ref.watch(dbProvider);
  return db.whenData((d) async => await d.getRepository<Todo>()).asData!.value;
}
