import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nitrite/nitrite.dart';
// ignore: implementation_imports
import 'package:nitrite/src/collection/operations/index_manager.dart';
import 'package:nitrite_support/src/exchange/convert/binary_reader.dart';
import 'package:nitrite_support/src/exchange/convert/converter_registry.dart';

import 'options.dart';

/// @nodoc
class NitriteJsonImporter {
  final ImportOptions _options;
  final ConverterRegistry _converterRegistry;

  NitriteJsonImporter(this._options) : _converterRegistry = ConverterRegistry();

  Future<void> import(String content) async {
    for (var element in _options.converters) {
      _converterRegistry.register(element);
    }

    Map<String, dynamic> json = jsonDecode(content);
    var db = await _options.dbFactory();

    if (json.containsKey(tagCollections)) {
      var collections = json[tagCollections];
      if (collections is List) {
        for (var collectionInfo in collections) {
          await _importNitriteMap(db, collectionInfo);
        }
      }
    }

    if (json.containsKey(tagRepositories)) {
      var repositories = json[tagRepositories];
      if (repositories is List) {
        for (var repositoryInfo in repositories) {
          await _importNitriteMap(db, repositoryInfo);
        }
      }
    }

    if (json.containsKey(tagKeyedRepositories)) {
      var keyedRepositories = json[tagKeyedRepositories];
      if (keyedRepositories is List) {
        for (var keyedRepositoryInfo in keyedRepositories) {
          await _importNitriteMap(db, keyedRepositoryInfo);
        }
      }
    }

    await db.close();
  }

  Future<void> _importNitriteMap(
      Nitrite db, Map<String, dynamic> nitriteMapInfo) async {
    var nitriteMapName = nitriteMapInfo[tagName];
    var store = db.getStore();
    var nitriteMap = await store.openMap(nitriteMapName);

    if (nitriteMapInfo.containsKey(tagIndices)) {
      var indicesInfo = nitriteMapInfo[tagIndices];
      if (indicesInfo is List) {
        await _importIndices(db, nitriteMapName, indicesInfo);
      }
    }

    if (nitriteMapInfo.containsKey(tagData)) {
      var dataInfo = nitriteMapInfo[tagData];
      if (dataInfo is List) {
        await _importContent(nitriteMap, dataInfo);
      }
    }

    await nitriteMap.close();
  }

  Future<void> _importIndices(
      Nitrite db, String nitriteMapName, List indicesInfo) async {
    var indexManager = IndexManager(nitriteMapName, db.config);
    await indexManager.initialize();

    for (var indexInfo in indicesInfo) {
      var document = _readEncodedObject<Document>(indexInfo);
      var indexDescriptor = IndexDescriptor.fromDocument(document);
      await indexManager.markIndexDirty(indexDescriptor);
    }

    await indexManager.close();
  }

  Future<void> _importContent(NitriteMap nitriteMap, List dataInfo) async {
    for (var data in dataInfo) {
      if (data is Map) {
        var keyEncoded = data[tagKey];
        var nitriteId = _readEncodedObject<NitriteId>(keyEncoded);

        var documentEncoded = data[tagValue];
        var document = _readEncodedObject<Document>(documentEncoded);

        await nitriteMap.put(nitriteId, document);
      }
    }
  }

  T _readEncodedObject<T>(String encodedString) {
    var gzipped = base64Decode(encodedString);
    var bytes = gzip.decode(gzipped);
    var binaryReader =
        BinaryReader(Uint8List.fromList(bytes), _converterRegistry);
    return binaryReader.read() as T;
  }
}
