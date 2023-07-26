import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/src/nitrite_json_exporter.dart';

class Exporter {
  final Nitrite _db;
  final ExportOptions _options;

  Exporter._(this._db, this._options);

  factory Exporter.of(
    Nitrite db, {
    ExportOptions exportOptions = const ExportOptions(),
  }) =>
      Exporter._(db, exportOptions);

  Future<void> exportTo(String path) async {
    return compute(_writeToFile, path);
  }

  void _writeToFile(String path) async {
    var file = File(path);
    var parent = file.parent;
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }

    var content = _writeToJson();
    await file.writeAsString(content);
  }

  String _writeToJson() {
    var jsonExporter = NitriteJsonExporter(_db, _options);
    return jsonExporter.export();
  }
}

class ExportOptions {
  final bool exportIndices;
  final bool exportData;
  final List<PersistentCollection> collections;

  const ExportOptions({
    this.exportIndices = true,
    this.exportData = true,
    this.collections = const [],
  });
}
