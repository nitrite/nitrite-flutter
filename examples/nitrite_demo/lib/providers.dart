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

  var db = await Nitrite.builder()
      .loadModule(storeModule)
      .fieldSeparator('.')
      .openOrCreate(username: 'demo', password: 'demo123');
  return db;
}

@riverpod
Future<ObjectRepository<Todo>> todoRepository(
    TodoRepositoryRef ref) async {
  var db = await ref.watch(dbProvider.future);
  return await db.getRepository<Todo>();
}

@riverpod
Stream<Todo> filteredTodos(FilteredTodosRef ref, Filter filter) async* {
  var repository = await ref.watch(todoRepositoryProvider.future);
  yield* await repository.find(filter: filter);
}

