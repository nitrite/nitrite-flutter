import 'package:nitrite/src/collection/nitrite_collection.dart';

abstract class ObjectRepository<T> {
  NitriteCollection? get documentCollection;
}
