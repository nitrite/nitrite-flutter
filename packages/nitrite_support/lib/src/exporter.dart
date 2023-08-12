import 'dart:io';

import 'package:compute/compute.dart';
import 'package:nitrite_support/src/convert/converter.dart';
import 'package:nitrite_support/src/nitrite_json_exporter.dart';
import 'package:nitrite_support/src/options.dart';

/// Nitrite database export utility. It exports data to
/// a json file. Contents of a Nitrite database can be exported
/// using this tool.
class Exporter {
  final ExportOptions _options;

  Exporter._(this._options);


  /// The `Exporter.withOptions` factory method creates an `Exporter` object 
  /// with the specified options for exporting data from a Nitrite database.
  /// 
  /// Args:
  ///   dbFactory (NitriteFactory): The `dbFactory` parameter is of type 
  /// `NitriteFactory` and is required. It represents the factory used to 
  /// create/open the Nitrite database.
  ///   exportIndices (bool): A boolean value indicating whether to export the 
  /// indices of the database.
  /// If set to true, the indices will be exported. If set to false, the 
  /// indices will not be exported. The default value is true. Defaults to true
  ///   exportData (bool): A boolean value indicating whether to export the data
  /// from the database. If set to true, the data will be exported; if set to 
  /// false, only the database structure will be exported. Defaults to true
  ///   collections (List<String>): A list of collection names to export. 
  /// If not provided, all collections will be exported. If an empty list is 
  /// provided, no collections will be exported. If a list of collection names
  /// is provided, only those collections will be exported.
  ///   repositories (List<String>): A list of repository names to export.
  /// If not provided, all repositories will be exported. If an empty list is
  /// provided, no repositories will be exported. If a list of repository names
  /// is provided, only those repositories will be exported.
  ///   keyedRepositories (Map<String, Set<String>>): A map of keyed-repositories
  /// to export. If not provided, all keyed-repositories will be exported. If an
  /// empty map is provided, no keyed-repositories will be exported. If a map of
  /// keyed-repositories is provided, only those keyed-repositories will be
  /// exported.
  factory Exporter.withOptions({
    required NitriteFactory dbFactory,
    bool exportIndices = true,
    bool exportData = true,
    List<String>? collections,
    List<String>? repositories,
    Map<String, Set<String>>? keyedRepositories
  }) =>
      Exporter._(ExportOptions(
        dbFactory: dbFactory,
        exportIndices: exportIndices,
        exportData: exportData,
        collections: collections,
        repositories: repositories,
        keyedRepositories: keyedRepositories,
      ));

  /// The function "registerConverter" is used to register a binary converter.
  /// 
  /// Args:
  ///   converter (Converter): The "converter" parameter is an object of type "Converter".
  void registerConverter(Converter converter) {
    _options.registerConverter(converter);
  }

  /// The function exports data to a json file at the specified path using a 
  /// separate isolate.
  /// 
  /// Args:
  ///   path (String): The `path` parameter is a string that represents the 
  /// file path where the data will be exported to.
  /// 
  /// Returns:
  ///   The `exportTo` function is returning a `Future<void>`.
  Future<void> exportTo(String path) async {
    return compute(_writeToFile, path);
  }

  void _writeToFile(String path) async {
    var file = File(path);
    var parent = file.parent;
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }

    var content = await _writeToJson();
    await file.writeAsString(content, flush: true, mode: FileMode.write);
  }

  Future<String> _writeToJson() async {
    var jsonExporter = NitriteJsonExporter(_options);
    return jsonExporter.export();
  }
}
