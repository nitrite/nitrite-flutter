import 'package:nitrite/src/nitrite_config.dart';
import 'package:nitrite/src/store/events/store_events.dart';

class EventInfo {
  StoreEvents event;
  NitriteConfig nitriteConfig;

  EventInfo(this.event, this.nitriteConfig);
}
