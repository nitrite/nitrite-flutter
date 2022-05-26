import 'package:nitrite/nitrite.dart';

/// A listener which is able to listen to any changes in a [NitriteCollection]
/// or [ObjectRepository].
typedef CollectionEventListener = void Function<T>(CollectionEventInfo<T> event);

/// Interface to be implemented by collections that wish to be aware
/// of any event.
abstract class EventAware {
  /// Subscribes an [CollectionEventListener] instance to listen to any
  /// collection events.
  void subscribe(CollectionEventListener listener);

  /// Unsubscribes an [CollectionEventListener] instance.
  void unsubscribe(CollectionEventListener listener);
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

  CollectionEventInfo(this.item, this.eventType,
      this.timestamp, this.originator);
}
