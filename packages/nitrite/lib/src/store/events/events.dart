import 'package:nitrite/nitrite.dart';

/// The nitrite event details.
class EventInfo {
  StoreEvents event;
  NitriteConfig nitriteConfig;

  EventInfo(this.event, this.nitriteConfig);
}

/// Represents an event listener for store events.
typedef StoreEventListener = void Function(EventInfo eventInfo);

/// Nitrite store related events.
enum StoreEvents { opened, commit, closing, closed }
