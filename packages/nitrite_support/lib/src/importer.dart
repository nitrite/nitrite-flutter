import 'package:flutter/foundation.dart';
import 'package:nitrite/nitrite.dart';

class Importer {
  final Nitrite _db;

  Importer._(this._db);

  factory Importer.of(Nitrite db) => Importer._(db);

  Future<void> importFrom(String path) async {
    return compute(_readFromFile, path);
  }

  void _readFromFile(String path) async {

  }
}
