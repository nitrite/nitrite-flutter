import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// Represents the configuration interface of a [NitriteStore].
abstract class StoreConfig {
  /// Gets the file path of the store.
  String? get filePath;

  /// Returns true if the store is read-only, false otherwise.
  bool get isReadOnly;

  /// Adds a [StoreEventListener] to the store configuration.
  /// The listener will be notified of any store events.
  void addStoreEventListener(StoreEventListener listener);

  /// Returns true if the store is in-memory, false otherwise.
  bool get isInMemory => filePath.isNullOrEmpty;

  // Returns a set of [StoreEventListener]s for the store.
  Set<StoreEventListener> get eventListeners;
}
