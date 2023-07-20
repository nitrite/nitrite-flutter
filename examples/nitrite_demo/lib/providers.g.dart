// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dbHash() => r'20067d9741d908cbb3721d0485fe990e95029e15';

/// See also [db].
@ProviderFor(db)
final dbProvider = AutoDisposeFutureProvider<Nitrite>.internal(
  db,
  name: r'dbProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dbHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DbRef = AutoDisposeFutureProviderRef<Nitrite>;
String _$todoRepositoryHash() => r'37d4cef7429727e605b6d1384dd4476407e09046';

/// See also [todoRepository].
@ProviderFor(todoRepository)
final todoRepositoryProvider =
    AutoDisposeFutureProvider<ObjectRepository<Todo>>.internal(
  todoRepository,
  name: r'todoRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todoRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TodoRepositoryRef
    = AutoDisposeFutureProviderRef<ObjectRepository<Todo>>;
String _$filteredTodosHash() => r'fba20c3487e964073410009fe7dfc46f31ce0e34';

/// See also [filteredTodos].
@ProviderFor(filteredTodos)
final filteredTodosProvider = AutoDisposeStreamProvider<Todo>.internal(
  filteredTodos,
  name: r'filteredTodosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredTodosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredTodosRef = AutoDisposeStreamProviderRef<Todo>;
String _$todosHash() => r'8d6ce5ae23b805d5c1a9b1acdb0ba2528f802999';

/// See also [Todos].
@ProviderFor(Todos)
final todosProvider =
    AutoDisposeAsyncNotifierProvider<Todos, Stream<Todo>>.internal(
  Todos.new,
  name: r'todosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Todos = AutoDisposeAsyncNotifier<Stream<Todo>>;
String _$findOptionStateHash() => r'58d1f116a6b55818f948b3929e0e4f0e171e3486';

/// See also [FindOptionState].
@ProviderFor(FindOptionState)
final findOptionStateProvider =
    AutoDisposeNotifierProvider<FindOptionState, FindOptions>.internal(
  FindOptionState.new,
  name: r'findOptionStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$findOptionStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FindOptionState = AutoDisposeNotifier<FindOptions>;
// ignore_for_file: unnecessary_raw_strings, subtype_of_sealed_class, invalid_use_of_internal_member, do_not_use_environment, prefer_const_constructors, public_member_api_docs, avoid_private_typedef_functions
