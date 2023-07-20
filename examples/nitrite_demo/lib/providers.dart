import 'package:flutter_riverpod/flutter_riverpod.dart';
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
Future<ObjectRepository<Todo>> todoRepository(TodoRepositoryRef ref) async {
  var db = await ref.watch(dbProvider.future);
  return await db.getRepository<Todo>();
}

@riverpod
Stream<Todo> filteredTodos(FilteredTodosRef ref) async* {
  var repository = await ref.watch(todoRepositoryProvider.future);
  var filter = ref.watch(filterProvider);
  var findOptions = ref.watch(findOptionStateProvider);
  yield* await repository.find(filter: filter, findOptions: findOptions);
}

@riverpod
class Todos extends _$Todos {
  Stream<Todo> _fetchTodo() async* {
    var repository = await ref.read(todoRepositoryProvider.future);
    var filter = ref.watch(filterProvider);
    var findOptions = ref.watch(findOptionStateProvider);
    yield* await repository.find(filter: filter, findOptions: findOptions);
  }

  @override
  Future<Stream<Todo>> build() async {
    return _fetchTodo();
  }

  Future<void> addTodo(Todo todo) async {
    state = const AsyncValue.loading();

    try {
      var repository = await ref.read(todoRepositoryProvider.future);
      await repository.insert(todo);
      state = AsyncData(_fetchTodo());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> removeTodo(String todoId) async {
    state = const AsyncValue.loading();
    try {
      var repository = await ref.read(todoRepositoryProvider.future);
      await repository.remove(where('id').eq(todoId));
      state = AsyncData(_fetchTodo());
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
      state = AsyncData(_fetchTodo());
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
