import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/concurrent/lock_service.dart';

class NitriteDatabase extends Nitrite {
  final LockService _lockService = LockService();
  final NitriteConfig _nitriteConfig;

  NitriteDatabase(this._nitriteConfig);

  @override
  Future<void> close() async {
    throw UnimplementedError();
  }

  @override
  Future<void> commit() async {
    throw UnimplementedError();
  }

  @override
  NitriteConfig get config => throw UnimplementedError();

  @override
  Session createSession() {
    throw UnimplementedError();
  }

  @override
  Future<StoreMetaData> get databaseMetaData async => throw UnimplementedError();

  @override
  Future<void> destroyCollection(String name) async {
    throw UnimplementedError();
  }

  @override
  Future<void> destroyRepository<T>([String? key]) async {
    throw UnimplementedError();
  }

  @override
  Future<NitriteCollection> getCollection(String name) async {
    throw UnimplementedError();
  }

  @override
  Future<ObjectRepository<T>> getRepository<T>([String? key]) async {
    throw UnimplementedError();
  }

  @override
  NitriteStore<T> getStore<T extends StoreConfig>() {
    throw UnimplementedError();
  }

  @override
  Future<bool> get hasUnsavedChanges async => throw UnimplementedError();

  @override
  bool get isClosed => throw UnimplementedError();

  @override
  Future<Set<String>> get listCollectionNames async => throw UnimplementedError();

  @override
  Future<Map<String, Set<String>>> get listKeyedRepositories async => throw UnimplementedError();

  @override
  Future<Set<String>> get listRepositories async => throw UnimplementedError();

  Future<void> initialize([String? username, String? password]) async {}

}
