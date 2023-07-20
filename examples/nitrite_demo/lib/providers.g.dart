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
String _$todoRepositoryProviderHash() =>
    r'a25501a9103fee0b04a290a9898241fafd4b22e2';

/// See also [todoRepositoryProvider].
@ProviderFor(todoRepositoryProvider)
final todoRepositoryProviderProvider =
    AutoDisposeFutureProvider<ObjectRepository<Todo>>.internal(
  todoRepositoryProvider,
  name: r'todoRepositoryProviderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todoRepositoryProviderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TodoRepositoryProviderRef
    = AutoDisposeFutureProviderRef<ObjectRepository<Todo>>;
// ignore_for_file: unnecessary_raw_strings, subtype_of_sealed_class, invalid_use_of_internal_member, do_not_use_environment, prefer_const_constructors, public_member_api_docs, avoid_private_typedef_functions
