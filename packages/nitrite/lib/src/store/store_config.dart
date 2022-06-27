import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// Represents a [NitriteStore] configuration.
abstract class StoreConfig {
  /// Gets file path for the store.
  String? get filePath;

  /// Indicates if the [NitriteStore] is a readonly store.
  bool get isReadOnly;

  /// Adds a [StoreEventListener] instance and subscribe it to store event.
  void addStoreEventListener(StoreEventListener listener);

  /// Indicates if the [NitriteStore] is an in-memory store.
  bool get isInMemory => filePath.isNullOrEmpty;

  /// Gets all [StoreEventListener] instances that would be subscribed
  /// with the [NitriteStore].
  Set<StoreEventListener> get eventListeners;
}
