import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_demo/models/models.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';


@riverpod
Future<Nitrite> db(DbRef ref) async {
  var docPath = await getApplicationDocumentsDirectory();
  var dbDir = await Directory('${docPath.path}${Platform.pathSeparator}db')
      .create(recursive: true);
  var storeModule =
      HiveModule.withConfig().crashRecovery(true).path(dbDir.path).build();

  var db = await Nitrite.builder()
      .loadModule(storeModule)
      .fieldSeparator('.')
      .openOrCreate(username: 'demo', password: 'demo123');

  var mapper = db.config.nitriteMapper as EntityConverterMapper;
  mapper.registerEntityConverter(TodoConverter());

  return db;
}

@riverpod
Future<ObjectRepository<Todo>> todoRepository(TodoRepositoryRef ref) async {
  var db = await ref.read(dbProvider.future);
  return await db.getRepository<Todo>();
}

@riverpod
class Todos extends _$Todos {
  Future<List<Todo>> _fetchTodo() async {
    var repository = await ref.read(todoRepositoryProvider.future);
    var filter = ref.watch(filterProvider);
    var findOptions = ref.watch(findOptionStateProvider);
    return repository.find(filter: filter, findOptions: findOptions).toList();
  }

  @override
  Future<List<Todo>> build() async {
    return _fetchTodo();
  }

  Future<void> addTodo(Todo todo) async {
    state = const AsyncValue.loading();

    try {
      var repository = await ref.read(todoRepositoryProvider.future);
      await repository.insert(todo);
      state = AsyncValue.data(await _fetchTodo());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> removeTodo(String todoId) async {
    state = const AsyncValue.loading();
    try {
      var repository = await ref.read(todoRepositoryProvider.future);
      await repository.remove(where('id').eq(todoId));
      state = AsyncValue.data(await _fetchTodo());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle(String todoId) async {
    state = const AsyncValue.loading();
    try {
      var repository = await ref.read(todoRepositoryProvider.future);
      var byId = await repository.getById(todoId);
      if (byId != null) {
        byId.completed = !byId.completed;
        await repository.updateOne(byId);
      }
      state = AsyncValue.data(await _fetchTodo());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

@riverpod
class FindOptionState extends _$FindOptionState {
  @override
  FindOptions build() {
    return FindOptions(
      orderBy: SortableFields.from([('title', SortOrder.ascending)]),
      skip: 0,
      limit: 10,
    );
  }
}

final filterProvider = StateProvider<Filter>((ref) => all);
final todoTextProvider = StateProvider<String>((ref) => '');

@riverpod
int pendingCounter(PendingCounterRef ref) {
  var todos = ref.watch(todosProvider);
  return todos.when(
    data: (todoList) => todoList.where((todo) => !todo.completed).length,
    loading: () => 0,
    error: (err, stack) => 0,
  );
}

@riverpod
int completedCounter(CompletedCounterRef ref) {
  var todos = ref.watch(todosProvider);
  return todos.when(
    data: (todoList) => todoList.where((todo) => todo.completed).length,
    loading: () => 0,
    error: (err, stack) => 0,
  );
}
