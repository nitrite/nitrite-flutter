import 'dart:convert';
import 'dart:io';

import 'package:nitrite/nitrite.dart';
// ignore: implementation_imports
import 'package:nitrite/src/collection/operations/index_manager.dart';
// ignore: implementation_imports
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite_support/src/exchange/convert/binary_writer.dart';
import 'package:nitrite_support/src/exchange/convert/converter_registry.dart';

import 'options.dart';

class NitriteJsonExporter {
  final ExportOptions _options;
  final ConverterRegistry _converterRegistry;

  NitriteJsonExporter(this._options) : _converterRegistry = ConverterRegistry();

  Future<String> export() async {
    for (var element in _options.converters) {
      _converterRegistry.register(element);
    }

    var db = await _options.dbFactory();

    var collectionNames = _options.collections == null
        ? await db.listCollectionNames
        : <String>{};
    var repositoryNames =
        _options.repositories == null ? await db.listRepositories : <String>{};
    var keyedRepositoryNames = _options.keyedRepositories == null
        ? await db.listKeyedRepositories
        : <String, Set<String>>{};
    var indexDescriptors = <IndexDescriptor>[];

    if (_options.collections != null && _options.collections!.isNotEmpty) {
      collectionNames.addAll(_options.collections!);
    }

    if (_options.repositories != null && _options.repositories!.isNotEmpty) {
      repositoryNames.addAll(_options.repositories!);
    }

    if (_options.keyedRepositories != null &&
        _options.keyedRepositories!.isNotEmpty) {
      keyedRepositoryNames.addAll(_options.keyedRepositories!);
    }

    if (_options.exportIndices) {
      for (var collectionName in collectionNames) {
        var indexManager = IndexManager(collectionName, db.config);
        await indexManager.initialize();
        indexDescriptors.addAll(await indexManager.getIndexDescriptors());
        await indexManager.close();
      }

      for (var repositoryName in repositoryNames) {
        var indexManager = IndexManager(repositoryName, db.config);
        await indexManager.initialize();
        indexDescriptors.addAll(await indexManager.getIndexDescriptors());
        await indexManager.close();
      }

      for (var entry in keyedRepositoryNames.entries) {
        var key = entry.key;
        var entityNameSet = entry.value;
        for (var entityName in entityNameSet) {
          var repositoryName = findRepositoryNameByTypeName(entityName, key);
          var indexManager = IndexManager(repositoryName, db.config);
          await indexManager.initialize();
          indexDescriptors.addAll(await indexManager.getIndexDescriptors());
          await indexManager.close();
        }
      }
    }

    var result = await _exportData(
      db,
      collectionNames,
      repositoryNames,
      keyedRepositoryNames,
      indexDescriptors,
    );

    await db.close();
    return result;
  }

  Future<String> _exportData(
      Nitrite db,
      Set<String> collectionNames,
      Set<String> repositoryNames,
      Map<String, Set<String>> keyedRepositoryNames,
      List<IndexDescriptor> indexDescriptors) async {
    var store = db.getStore();
    var json = StringBuffer();
    json.write('{');
    json.write(
        await _exportCollections(collectionNames, indexDescriptors, store));
    json.write(
        await _exportRepositories(repositoryNames, indexDescriptors, store));
    json.write(await _exportKeyedRepositories(
        keyedRepositoryNames, indexDescriptors, store));

    json.write('}');
    return json.toString();
  }

  Future<String> _exportCollections(Set<String> collectionNames,
      List<IndexDescriptor> indexDescriptors, NitriteStore store) async {
    var json = StringBuffer();
    json.write('"$tagCollections":[');
    var first = true;
    for (var collectionName in collectionNames) {
      if (!first) {
        json.write(',');
      }
      first = false;
      var nitriteMap = await store.openMap(collectionName);
      var indices = indexDescriptors
          .where((element) => element.collectionName == nitriteMap.name);
      json.write(await _exportMap(nitriteMap, indices));
      await nitriteMap.close();
    }
    json.write('],');
    return json.toString();
  }

  Future<String> _exportRepositories(Set<String> repositoryNames,
      List<IndexDescriptor> indexDescriptors, NitriteStore store) async {
    var json = StringBuffer();
    json.write('"$tagRepositories":[');
    var first = true;
    for (var repositoryName in repositoryNames) {
      if (!first) {
        json.write(',');
      }
      first = false;
      var nitriteMap = await store.openMap(repositoryName);
      var indices = indexDescriptors
          .where((element) => element.collectionName == nitriteMap.name);
      json.write(await _exportMap(nitriteMap, indices));
      await nitriteMap.close();
    }
    json.write('],');
    return json.toString();
  }

  Future<String> _exportKeyedRepositories(
      Map<String, Set<String>> keyedRepositoryNames,
      List<IndexDescriptor> indexDescriptors,
      NitriteStore store) async {
    var json = StringBuffer();
    json.write('"$tagKeyedRepositories":[');
    var first = true;
    for (var entry in keyedRepositoryNames.entries) {
      if (!first) {
        json.write(',');
      }
      first = false;
      var key = entry.key;
      var typeNames = entry.value;
      var firstType = true;
      for (var typeName in typeNames) {
        if (!firstType) {
          json.write(',');
        }
        firstType = false;
        var mapName = findRepositoryNameByTypeName(typeName, key);
        var nitriteMap = await store.openMap(mapName);
        var indices = indexDescriptors
            .where((element) => element.collectionName == nitriteMap.name);
        json.write(await _exportMap(nitriteMap, indices));
        await nitriteMap.close();
      }
    }
    json.write(']');
    return json.toString();
  }

  Future<String> _exportMap(
      NitriteMap nitriteMap, Iterable<IndexDescriptor> indices) async {
    var json = StringBuffer();
    json.write('{');

    json.write('"$tagName":"${nitriteMap.name}",');
    json.write(await _exportIndices(indices));
    json.write(await _exportContent(nitriteMap));

    json.write('}');
    return json.toString();
  }

  Future<String> _exportIndices(Iterable<IndexDescriptor> indices) async {
    var json = StringBuffer();
    json.write('"$tagIndices":[');
    var first = true;
    for (var index in indices) {
      if (!first) {
        json.write(',');
      }
      first = false;
      json.write('"${_exportIndex(index)}"');
    }
    json.write('],');
    return json.toString();
  }

  Future<String> _exportContent(NitriteMap nitriteMap) async {
    var json = StringBuffer();
    json.write('"$tagData":[');
    if (_options.exportData) {
      var first = true;

      await for (var pair in nitriteMap.entries()) {
        if (!first) {
          json.write(',');
        }
        first = false;
        json.write(_exportPair(pair));
      }
    }
    json.write(']');
    return json.toString();
  }

  String _exportPair((dynamic, dynamic) pair) {
    var json = StringBuffer();
    json.write('{');
    json.write('"$tagKey":');
    json.write('"${_writeEncodedObject(pair.$1)}"');
    json.write(',"$tagValue":');
    json.write('"${_writeEncodedObject((pair.$2))}"');
    json.write('}');
    return json.toString();
  }

  String _exportIndex(IndexDescriptor index) {
    return _writeEncodedObject(index.toDocument());
  }

  String _writeEncodedObject(dynamic object) {
    var binaryWriter = BinaryWriter(_converterRegistry);
    binaryWriter.write(object);
    var gzipped = gzip.encode(binaryWriter.toBytes());
    return base64.encode(gzipped);
  }
}
