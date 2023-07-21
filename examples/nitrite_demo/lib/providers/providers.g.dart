// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dbHash() => r'97229d1bc5ba80b114cb6c4b84f54d8b2a664bc2';

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
String _$pendingCounterHash() => r'8a0d1f9acf3521f7e9c3f425e80ed2e6c37158d1';

/// See also [pendingCounter].
@ProviderFor(pendingCounter)
final pendingCounterProvider = AutoDisposeFutureProvider<int>.internal(
  pendingCounter,
  name: r'pendingCounterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingCounterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingCounterRef = AutoDisposeFutureProviderRef<int>;
String _$completedCounterHash() => r'c39abd09987554b0ba7fda7e13b4b99dbcc628e5';

/// See also [completedCounter].
@ProviderFor(completedCounter)
final completedCounterProvider = AutoDisposeFutureProvider<int>.internal(
  completedCounter,
  name: r'completedCounterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$completedCounterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CompletedCounterRef = AutoDisposeFutureProviderRef<int>;
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
