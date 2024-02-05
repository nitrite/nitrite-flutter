import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/store/meta_data.dart';

/// The Nitrite store catalog containing the name of all collections,
/// repositories and keyed-repositories.
class StoreCatalog {
  final NitriteStore _nitriteStore;

  late NitriteMap<String, Document> _catalog;

  StoreCatalog(this._nitriteStore);

  Future<void> initialize() async {
    _catalog = await _nitriteStore.openMap<String, Document>(collectionCatalog);
  }

  /// Returns a [Future] that completes with a [bool] indicating whether
  /// the store catalog has an entry with the given name.
  Future<bool> hasEntry(String name) async {
    await for (var entry in _catalog.entries()) {
      var metaData = MapMetaData(entry.$2);
      if (metaData.mapNames.contains(name)) {
        return Future.value(true);
      }
    }
    return Future.value(false);
  }

  /// Writes a new entry for a collection with the given name to
  /// the store catalog.
  Future<void> writeCollectionEntry(String name) async {
    var document = await _catalog[tagCollections];
    document ??= emptyDocument();

    // parse the document to create collection metadata object
    var mapMetaData = MapMetaData(document);
    mapMetaData.mapNames.add(name);

    // convert the metadata object to document and save
    await _catalog.put(tagCollections, mapMetaData.getInfo());
  }

  /// Writes a repository entry with the given name to the store catalog.
  Future<void> writeRepositoryEntry(String name) async {
    var document = await _catalog[tagRepositories];
    document ??= emptyDocument();

    // parse the document to create repository metadata object
    var mapMetaData = MapMetaData(document);
    mapMetaData.mapNames.add(name);

    // convert the metadata object to document and save
    await _catalog.put(tagRepositories, mapMetaData.getInfo());
  }

  /// Writes a keyed repository entry to the store catalog.
  Future<void> writeKeyedRepositoryEntry(String name) async {
    var document = await _catalog[tagKeyedRepositories];
    document ??= emptyDocument();

    // parse the document to create repository metadata object
    var mapMetaData = MapMetaData(document);
    mapMetaData.mapNames.add(name);

    // convert the metadata object to document and save
    await _catalog.put(tagKeyedRepositories, mapMetaData.getInfo());
  }

  /// Returns a [Future] that completes with a [Set] of all
  /// collection names in the Nitrite database.
  Future<Set<String>> get collectionNames async {
    var doc = await _catalog[tagCollections];
    if (doc == null) {
      return <String>{};
    }

    var metaData = MapMetaData(doc);
    return metaData.mapNames;
  }

  /// Returns a [Future] that completes with a [Set] of all
  /// repository names in the Nitrite database.
  Future<Set<String>> get repositoryNames async {
    var doc = await _catalog[tagRepositories];
    if (doc == null) {
      return <String>{};
    }

    var metaData = MapMetaData(doc);
    return metaData.mapNames;
  }

  /// Returns a [Future] that completes with a [Set] of all
  /// keyed repository names in the Nitrite database.
  Future<Map<String, Set<String>>> get keyedRepositoryNames async {
    var doc = await _catalog[tagKeyedRepositories];
    if (doc == null) {
      return <String, Set<String>>{};
    }

    var metaData = MapMetaData(doc);
    var keyedRepositoryNames = metaData.mapNames;

    var resultMap = <String, Set<String>>{};
    for (var field in keyedRepositoryNames) {
      var key = getKeyName(field);
      var type = getKeyedRepositoryType(field);

      Set<String>? types;
      if (resultMap.containsKey(key)) {
        types = resultMap[key];
      } else {
        types = <String>{};
      }
      types?.add(type);
      resultMap[key] = types!;
    }

    return resultMap;
  }

  /// Removes the entry from the catalog specified by a name.
  Future<void> remove(String name) async {
    // iterate over all types of catalog and find which type contains the name
    // remove the name from there
    await for ((String, Document) entry in _catalog.entries()) {
      var catalog = entry.$1;
      var doc = entry.$2;
      var metaData = MapMetaData(doc);
      if (metaData.mapNames.contains(name)) {
        metaData.mapNames.remove(name);
        await _catalog.put(catalog, metaData.getInfo());
      }
    }
  }
}
