import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/initializable.dart';

/// Represents an R-Tree in the nitrite database.
abstract class NitriteRTree<Key, Value> implements Initializable {
  /// Adds a key to the rtree.
  Future<void> add(Key? key, NitriteId? value);

  /// Removes a key from the rtree.
  Future<void> remove(Key? key, NitriteId? value);

  /// Finds the intersecting keys from the rtree.
  Stream<NitriteId> findIntersectingKeys(Key? key);

  /// Finds the contained keys from the rtree.
  Stream<NitriteId> findContainedKeys(Key? key);

  /// Finds the [k] nearest neighbours of the point ([x], [y]), ordered by
  /// ascending distance from the point to each stored bounding box.
  ///
  /// If [maxDistance] is given, entries whose bounding box is farther than
  /// that distance are excluded.
  Stream<NitriteId> findNearestNeighbors(
    double x,
    double y,
    int k, [
    double? maxDistance,
  ]);

  /// Gets the size of the rtree.
  Future<int> size();

  /// Closes this [NitriteRTree] instance.
  Future<void> close();

  /// Clears the data.
  Future<void> clear();

  /// Drops this instance.
  Future<void> drop();
}
