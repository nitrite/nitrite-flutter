import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/meta/attributes.dart';

/// The interface Persistent collection.
abstract class PersistentCollection<T> implements EventAware, AttributesAware {
  /// Adds a data processor to this collection.
  void addProcessor(Processor processor);

  /// Creates an index on the [fields], if not already exists.
  /// If [indexOptions] is [null], it will use default options.
  /// <p>
  /// The default indexing option is -
  ///
  /// ```dart
  /// indexOptions.indexType = IndexType.unique;
  /// ```
  ///
  /// NOTE:
  /// - **_id** field is always indexed.
  /// - Indexing on non-comparable value is not supported.
  Future<void> createIndex(List<String> fields, [IndexOptions? indexOptions]);

  /// Rebuilds index on the [fields] if it exists.
  Future<void> rebuildIndex(List<String> fields);


}
