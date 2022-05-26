import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/concurrent/lock_service.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

class CollectionFactory {
  final Map<String, NitriteCollection> _collectionMap = {};
  final LockService _lockService;

  CollectionFactory(this._lockService);

  Future<NitriteCollection> getCollection(String name,
      NitriteConfig nitriteConfig, bool writeCatalogue) async {

    nitriteConfig.notNullOrEmpty('Configuration is null while '
        'creating collection');
    name.notNullOrEmpty('Collection name is null or empty');

    var lock = await _lockService.getLock(name);
    return await lock.protectWrite(() async {
      if (_collectionMap.containsKey(name)) {
        var collection = _collectionMap[name]!;
        if (collection.isDropped || !collection.isOpen) {
          _collectionMap.remove(name);
          return await _createCollection(name, nitriteConfig, writeCatalogue);
        }
        return _collectionMap[name]!;
      } else {
        return await _createCollection(name, nitriteConfig, writeCatalogue);
      }
    });
  }

  Future<void> clear() async {
    var lock = await _lockService.getLock('CollectionFactory');
    return await lock.protectWrite(() async {
      try {
        _collectionMap.forEach((key, value) async {
          await value.close();
        });
        _collectionMap.clear();
      } catch (e) {
        throw NitriteIOException("Failed to close a collection");
      }
    });
  }

  Future<NitriteCollection> _createCollection(String name,
      NitriteConfig nitriteConfig, bool writeCatalogue) async {
    var store = nitriteConfig.getNitriteStore();
    var nitriteMap = await store.openMap<NitriteId, Document>(name);
    var collection = NitriteCollection.create(name, nitriteMap, nitriteConfig,
        _lockService);

    if (writeCatalogue) {
      var repoRegistry = await store.repositoryRegistry;
      if (repoRegistry.contains(name)) {
        await nitriteMap.close();
        await collection.close();
        throw ValidationException("A repository with same name already exists");
      }

      var keyedRepoRegistry = await store.keyedRepositoryRegistry;
      for (var set in keyedRepoRegistry.values) {
        if (set.contains(name)) {
          await nitriteMap.close();
          await collection.close();
          throw ValidationException("A keyed repository with same name "
              "already exists");
        }
      }

      _collectionMap[name] = collection;
      var storeCatalog = store.catalog;
      await storeCatalog.writeCollectionEntry(name);
    }

    return collection;
  }
}
