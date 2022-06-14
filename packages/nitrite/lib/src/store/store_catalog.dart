import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/constants.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/store/meta_data.dart';

class StoreCatalog {
  final NitriteStore _nitriteStore;

  late NitriteMap<String, Document> _catalog;

  StoreCatalog(this._nitriteStore);

  Future<void> init() async {
    _catalog = await _nitriteStore.openMap<String, Document>(collectionCatalog);
  }

  Future<void> writeCollectionEntry(String name) async {
    var document = await _catalog[tagCollections];
    document ??= Document.emptyDocument();

    // parse the document to create collection meta data object
    var mapMetaData = MapMetaData(document);
    mapMetaData.mapNames.add(name);

    // convert the meta data object to document and save
    await _catalog.put(tagCollections, mapMetaData.getInfo());
  }

  Future<void> writeRepositoryEntry(String name) async {
    var document = await _catalog[tagRepositories];
    document ??= Document.emptyDocument();

    // parse the document to create repository meta data object
    var mapMetaData = MapMetaData(document);
    mapMetaData.mapNames.add(name);

    // convert the meta data object to document and save
    await _catalog.put(tagRepositories, mapMetaData.getInfo());
  }

  Future<void> writeKeyedRepositoryEntry(String name) async {
    var document = await _catalog[tagKeyedRepositories];
    document ??= Document.emptyDocument();

    // parse the document to create repository meta data object
    var mapMetaData = MapMetaData(document);
    mapMetaData.mapNames.add(name);

    // convert the meta data object to document and save
    await _catalog.put(tagKeyedRepositories, mapMetaData.getInfo());
  }

  Future<Set<String>> get collectionNames async {
    var doc = await _catalog[tagCollections];
    if (doc == null) {
      return <String>{};
    }

    var metaData = MapMetaData(doc);
    return metaData.mapNames;
  }

  Future<Set<String>> get repositoryNames async {
    var doc = await _catalog[tagRepositories];
    if (doc == null) {
      return <String>{};
    }

    var metaData = MapMetaData(doc);
    return metaData.mapNames;
  }

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

  Future<void> remove(String name) async {
    // iterate over all types of catalog and find which type contains the name
    // remove the name from there
    await for (Pair<String, Document> entry in _catalog.entries()) {
      var catalog = entry.first;
      var doc = entry.second;
      var metaData = MapMetaData(doc);
      if (metaData.mapNames.contains(name)) {
        metaData.mapNames.remove(name);
        await _catalog.put(catalog, metaData.getInfo());
      }
    }
  }
}
