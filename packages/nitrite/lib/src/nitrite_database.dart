import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/collection_factory.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/migration/migration_manager.dart';
import 'package:nitrite/src/repository/repository_factory.dart';
import 'package:nitrite/src/store/user_auth_service.dart';

/// @nodoc
class NitriteDatabase extends Nitrite {
  static final Logger _log = Logger('NitriteDatabase');

  final NitriteConfig _nitriteConfig;

  late CollectionFactory _collectionFactory;
  late RepositoryFactory _repositoryFactory;
  late NitriteMap<String, Document> _storeInfo;
  late NitriteStore _nitriteStore;

  NitriteDatabase(this._nitriteConfig) {
    _collectionFactory = CollectionFactory();
    _repositoryFactory = RepositoryFactory(_collectionFactory);
  }

  @override
  Future<Set<String>> get listCollectionNames {
    checkOpened();
    return _nitriteStore.collectionNames;
  }

  @override
  Future<Set<String>> get listRepositories {
    checkOpened();
    return _nitriteStore.repositoryRegistry;
  }

  @override
  Future<Map<String, Set<String>>> get listKeyedRepositories async {
    checkOpened();
    return _nitriteStore.keyedRepositoryRegistry;
  }

  @override
  Future<bool> get hasUnsavedChanges {
    checkOpened();
    return _nitriteStore.hasUnsavedChanges;
  }

  @override
  bool get isClosed => _nitriteStore.isClosed;

  @override
  NitriteConfig get config => _nitriteConfig;

  @override
  Future<StoreMetaData> get databaseMetaData async {
    var doc = await _storeInfo[storeInfo];
    if (doc == null) {
      await _prepareDatabaseMetaData();
      doc = await _storeInfo[storeInfo];
    }
    return StoreMetaData.fromDocument(doc!);
  }

  @override
  Future<NitriteCollection> getCollection(String name) async {
    validateCollectionName(name);
    checkOpened();
    return _collectionFactory.getCollection(name, _nitriteConfig, true);
  }

  @override
  Future<ObjectRepository<T>> getRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key}) async {
    checkOpened();
    return _repositoryFactory.getRepository<T>(
        _nitriteConfig, entityDecorator, key);
  }

  @override
  Future<void> destroyCollection(String name) async {
    checkOpened();
    return _nitriteStore.removeMap(name);
  }

  @override
  Future<void> destroyRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key}) async {
    checkOpened();
    var mapName = entityDecorator == null
        ? findRepositoryNameByType<T>(_nitriteConfig.nitriteMapper, key)
        : findRepositoryNameByDecorator(entityDecorator, key);
    return _nitriteStore.removeMap(mapName);
  }

  @override
  NitriteStore<T> getStore<T extends StoreConfig>() =>
      _nitriteStore as NitriteStore<T>;

  @override
  Future<void> close() async {
    checkOpened();
    try {
      await _nitriteStore.beforeClose();
      if (await hasUnsavedChanges) {
        _log.fine('Unsaved changes detected, committing the changes.');
        await _nitriteStore.commit();
      }

      await _repositoryFactory.clear();
      await _collectionFactory.clear();
      await _storeInfo.close();
      // close all plugins and store
      await _nitriteConfig.close();

      _log.info('Nitrite database has been closed successfully.');
    } on NitriteIOException {
      rethrow;
    } on Exception catch (e, stackTrace) {
      throw NitriteIOException('Error occurred while closing the database',
          stackTrace: stackTrace, cause: e);
    }
  }

  @override
  Future<void> commit() async {
    checkOpened();
    try {
      await _nitriteStore.commit();
    } catch (e, stackTrace) {
      throw NitriteIOException('Error occurred while committing the database',
          stackTrace: stackTrace, cause: e);
    }
    _log.fine('Unsaved changes has been committed successfully.');
  }

  @override
  Session createSession() {
    return Session(this);
  }

  Future<void> initialize([String? username, String? password]) async {
    _validateUserCredentials(username, password);
    try {
      await _nitriteConfig.initialize();
      _nitriteStore = _nitriteConfig.getNitriteStore();

      await _nitriteStore.openOrCreate();
      await _prepareDatabaseMetaData();

      var nitriteMapper = _nitriteConfig.nitriteMapper;
      var migrationManager = MigrationManager(this, nitriteMapper);
      await migrationManager.initialize();
      await migrationManager.doMigrate();

      var authService = UserAuthenticationService(_nitriteStore);
      await authService.authenticate(username, password);
    } catch (e, stackTrace) {
      _log.severe(
          'Error occurred while initializing the database', e, stackTrace);
      if (!_nitriteStore.isClosed) {
        try {
          await _nitriteStore.close();
        } on Exception catch (e, stackTrace) {
          _log.severe(
              'Error occurred while closing the database', e, stackTrace);
          throw NitriteIOException('Failed to close database',
              stackTrace: stackTrace, cause: e);
        }
      }

      if (e is NitriteException) {
        rethrow;
      } else {
        throw NitriteIOException('Failed to initialize database',
            stackTrace: stackTrace, cause: e);
      }
    }
  }

  void _validateUserCredentials(String? username, String? password) {
    if (username.isNullOrEmpty && password.isNullOrEmpty) {
      return;
    }

    if (username.isNullOrEmpty) {
      throw NitriteSecurityException('Username is required');
    }

    if (password.isNullOrEmpty) {
      throw NitriteSecurityException('Password is required');
    }
  }

  Future<void> _prepareDatabaseMetaData() async {
    _storeInfo = await _nitriteStore.openMap<String, Document>(storeInfo);
    if (await _storeInfo.isEmpty()) {
      var storeMetadata = StoreMetaData()
        ..createTime = DateTime.now().millisecondsSinceEpoch
        ..storeVersion = _nitriteStore.storeVersion
        ..nitriteVersion = nitriteVersion
        ..schemaVersion = _nitriteConfig.schemaVersion;

      await _storeInfo.put(storeInfo, storeMetadata.getInfo());
    }
  }
}
