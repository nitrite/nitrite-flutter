import 'dart:io';

import 'package:compute/compute.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/src/exchange/convert/converter.dart';

import 'nitrite_json_importer.dart';
import 'options.dart';

class Importer {
  final ImportOptions _options;

  Importer._(this._options);

  factory Importer.withConfig({
    required NitriteFactory dbFactory,
  }) =>
      Importer._(ImportOptions(
        dbFactory: dbFactory,
      ));

  void registerConverter(Converter converter) {
    _options.registerConverter(converter);
  }

  Future<void> importFrom(String path) async {
    return compute(_readFromFile, path);
  }

  Future<void> _readFromFile(String path) async {
    var file = File(path);
    if (file.existsSync()) {
      var content = await file.readAsString();
      await _readFromJson(content);
    } else {
      throw NitriteIOException('File not found: $path');
    }
  }

  Future<void> _readFromJson(String content) async {
    var jsonImporter = NitriteJsonImporter(_options);
    await jsonImporter.import(content);
  }
}