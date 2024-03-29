import 'package:nitrite/src/collection/events/event_aware.dart';
import 'package:test/test.dart';

void main() {
  var eventAwareTest = EventAwareTest();

  group(retry: 3, 'EventAware Test Suite', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Subscription Test', () {
      eventAwareTest.subscribe((event) {});
      expect(eventAwareTest.subscribed, 1);
    });

    test('Unsubscription Test', () {
      eventAwareTest.unsubscribe((event) {});
      expect(eventAwareTest.unsubscribed, 1);
    });
  });
}

class EventAwareTest implements EventAware {
  int subscribed = 0;
  int unsubscribed = 0;

  @override
  Future<void> subscribe<T>(CollectionEventListener<T> listener) async {
    subscribed++;
  }

  @override
  Future<void> unsubscribe<T>(CollectionEventListener<T> listener) async {
    unsubscribed++;
  }
}
