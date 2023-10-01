import 'package:nitrite/nitrite.dart';

/// Represents an event information object that contains the event
/// type and Nitrite configuration.
class EventInfo {
  StoreEvents event;
  NitriteConfig nitriteConfig;

  EventInfo(this.event, this.nitriteConfig);
}

/// A function type that defines the signature of a store event listener.
typedef StoreEventListener = void Function(EventInfo eventInfo);

/// An enumeration of events that can occur in a Nitrite store.
enum StoreEvents {
  /// Event emitted when a Nitrite database is opened.
  opened,

  /// Event emitted when a commit is made to the database.
  commit,

  /// Event emitted when a Nitrite database is about to close.
  closing,

  /// Event emitted when a Nitrite database is closed.
  closed
}
