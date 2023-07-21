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
String _$todoRepositoryHash() => r'245700cd989fea0b96a5b1a4c17479242318d1f1';

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
String _$pendingCounterHash() => r'b7050ba83c927afc6dd22f86e3b200603730fe68';

/// See also [pendingCounter].
@ProviderFor(pendingCounter)
final pendingCounterProvider = AutoDisposeProvider<int>.internal(
  pendingCounter,
  name: r'pendingCounterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingCounterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingCounterRef = AutoDisposeProviderRef<int>;
String _$completedCounterHash() => r'f8c20c82412294eed15d94647623dbcdd1d061f0';

/// See also [completedCounter].
@ProviderFor(completedCounter)
final completedCounterProvider = AutoDisposeProvider<int>.internal(
  completedCounter,
  name: r'completedCounterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$completedCounterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CompletedCounterRef = AutoDisposeProviderRef<int>;
String _$todosHash() => r'f1bf03830d15a37c43a1e02aa6a011d8819268ab';

/// See also [Todos].
@ProviderFor(Todos)
final todosProvider =
    AutoDisposeAsyncNotifierProvider<Todos, List<Todo>>.internal(
  Todos.new,
  name: r'todosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Todos = AutoDisposeAsyncNotifier<List<Todo>>;
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
