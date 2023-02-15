import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:nitrite_entity_generator/src/type_checker.dart';

extension IterableExtension<T> on Iterable<T> {
  // discard null values and transform only non-null values
  Iterable<R> mapNotNull<R>(R? Function(T element) transform) sync* {
    for (final element in this) {
      final transformed = transform(element);
      if (transformed != null) yield transformed;
    }
  }
}

extension FieldElementExtension on FieldElement {
  // field should not be static or synthetic
  bool shouldBeIncluded() {
    return !(isStatic || isSynthetic);
  }
}

extension AnnotationChecker on Element {
  bool hasAnnotation(final Type type) {
    return typeChecker(type).hasAnnotationOfExact(this);
  }

  /// Returns the first annotation object found of [type]
  /// or `null` if annotation of [type] not found
  DartObject? getAnnotation(final Type type) {
    return typeChecker(type).firstAnnotationOfExact(this);
  }
}