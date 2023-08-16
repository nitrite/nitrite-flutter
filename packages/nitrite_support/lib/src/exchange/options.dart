import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/src/exchange/convert/converter.dart';

/// A function to create/open a `Nitrite` instance.
typedef NitriteFactory = Future<Nitrite> Function();

class ImportOptions {
  final List<Converter> converters = [];
  final NitriteFactory dbFactory;

  ImportOptions({
    required this.dbFactory,
  });

  void registerConverter(Converter converter) {
    converters.add(converter);
  }
}

class ExportOptions {
  final bool exportIndices;
  final bool exportData;
  final NitriteFactory dbFactory;
  final List<String>? collections;
  final List<String>? repositories;
  final Map<String, Set<String>>? keyedRepositories;
  final List<Converter> converters = [];

  ExportOptions({
    required this.dbFactory,
    this.exportIndices = true,
    this.exportData = true,
    this.collections,
    this.repositories,
    this.keyedRepositories,
  });

  void registerConverter(Converter converter) {
    converters.add(converter);
  }
}
