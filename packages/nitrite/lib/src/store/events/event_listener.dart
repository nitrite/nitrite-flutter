import 'package:nitrite/nitrite.dart';

abstract class StoreEventListener {
  void onEvent(EventInfo eventInfo);
}
