import 'package:nitrite/nitrite.dart';

/// A listener which is able to listen to any changes in a [NitriteCollection]
/// or [ObjectRepository].
typedef CollectionEventListener<T> = void Function(
    CollectionEventInfo<T> event);

/// @nodoc
abstract class EventAware {
  void subscribe<T>(CollectionEventListener<T> listener);
  void unsubscribe<T>(CollectionEventListener<T> listener);
}

/// Represents different types of collection events.
enum EventType {
  /// Insert event.
  insert,

  /// Update event.
  update,

  /// Remove event.
  remove,

  /// Indexing start event.
  indexStart,

  /// Indexing end event.
  indexEnd
}

/// Represents a collection event data.
class CollectionEventInfo<T> {
  /// Specifies the item triggering the event.
  T item;

  /// Specifies the event type.
  EventType eventType;

  /// Specifies the unix timestamp of the change.
  int timestamp;

  /// Specifies the name of the originator who has initiated this event.
  String originator;

  CollectionEventInfo(
      {required this.item,
      required this.eventType,
      required this.timestamp,
      required this.originator});
}
