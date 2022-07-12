import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/initializable.dart';

/// Represents an R-Tree in the nitrite database.
abstract class NitriteRTree<Key, Value> implements Initializable {

  /// Adds a key to the rtree.
  Future<void> add(Key key, NitriteId? value);

  /// Removes a key from the rtree.
  Future<void> remove(Key key, NitriteId? value);

  /// Finds the intersecting keys from the rtree.
  Stream<NitriteId> findIntersectingKeys(Key key);

  /// Finds the contained keys from the rtree.
  Stream<NitriteId> findContainedKeys(Key key);

  /// Gets the size of the rtree.
  Future<int> get size;

  /// Closes this [NitriteRTree] instance.
  Future<void> close();

  /// Clears the data.
  Future<void> clear();

  /// Drops this instance.
  Future<void> drop();
}
