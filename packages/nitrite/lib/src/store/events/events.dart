import 'package:nitrite/nitrite.dart';

class EventInfo {
  StoreEvents event;
  NitriteConfig nitriteConfig;

  EventInfo(this.event, this.nitriteConfig);
}

typedef StoreEventListener = void Function(EventInfo eventInfo);

enum StoreEvents { opened, commit, closing, closed }
