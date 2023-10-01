import 'dart:io';

import 'package:compute/compute.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/src/exchange/convert/converter.dart';

import 'nitrite_json_importer.dart';
import 'options.dart';

/// The Importer class provides methods to import data from a file
/// or stream into Nitrite database.
class Importer {
  final ImportOptions _options;

  Importer._(this._options);

  /// Creates a new [Importer] instance with the given configuration.
  /// 
  /// Args:
  /// 
  ///   dbFactory (NitriteFactory): The `dbFactory` parameter is of type
  /// `NitriteFactory` and is required. It represents the factory used to
  /// create/open the Nitrite database.
  factory Importer.withConfig({
    required NitriteFactory dbFactory,
  }) =>
      Importer._(ImportOptions(
        dbFactory: dbFactory,
      ));

  /// The function "registerConverter" is used to register a binary converter.
  ///
  /// Args:
  ///   converter (Converter): The "converter" parameter is an object of type 
  /// [Converter].
  void registerConverter(Converter converter) {
    _options.registerConverter(converter);
  }

  /// Imports data from the given [path] into the Nitrite database.
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
