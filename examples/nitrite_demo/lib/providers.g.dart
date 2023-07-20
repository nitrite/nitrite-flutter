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
String _$filteredTodosHash() => r'e64cb5ae487b6862076189b2facef826e714fbce';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

typedef FilteredTodosRef = AutoDisposeStreamProviderRef<Todo>;

/// See also [filteredTodos].
@ProviderFor(filteredTodos)
const filteredTodosProvider = FilteredTodosFamily();

/// See also [filteredTodos].
class FilteredTodosFamily extends Family<AsyncValue<Todo>> {
  /// See also [filteredTodos].
  const FilteredTodosFamily();

  /// See also [filteredTodos].
  FilteredTodosProvider call(
    Filter filter,
  ) {
    return FilteredTodosProvider(
      filter,
    );
  }

  @override
  FilteredTodosProvider getProviderOverride(
    covariant FilteredTodosProvider provider,
  ) {
    return call(
      provider.filter,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'filteredTodosProvider';
}

/// See also [filteredTodos].
class FilteredTodosProvider extends AutoDisposeStreamProvider<Todo> {
  /// See also [filteredTodos].
  FilteredTodosProvider(
    this.filter,
  ) : super.internal(
          (ref) => filteredTodos(
            ref,
            filter,
          ),
          from: filteredTodosProvider,
          name: r'filteredTodosProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filteredTodosHash,
          dependencies: FilteredTodosFamily._dependencies,
          allTransitiveDependencies:
              FilteredTodosFamily._allTransitiveDependencies,
        );

  final Filter filter;

  @override
  bool operator ==(Object other) {
    return other is FilteredTodosProvider && other.filter == filter;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filter.hashCode);

    return _SystemHash.finish(hash);
  }
}
// ignore_for_file: unnecessary_raw_strings, subtype_of_sealed_class, invalid_use_of_internal_member, do_not_use_environment, prefer_const_constructors, public_member_api_docs, avoid_private_typedef_functions
