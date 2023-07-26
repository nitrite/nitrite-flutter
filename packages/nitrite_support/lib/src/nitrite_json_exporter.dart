import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/src/exporter.dart';

class NitriteJsonExporter {
  final Nitrite _db;
  final ExportOptions _options;

  NitriteJsonExporter(this._db, this._options);

  String export() {
    return '';
  }
}
