import 'package:nitrite/src/common/concurrent/lock_service.dart';
import 'package:test/test.dart';

void main() {
  group('Lock Service Test Suite', () {
    setUp(() {});

    test('Test GetLock', () async {
      var lockService = LockService();
      var lock = await lockService.getLock("test");
      expect(lock.isLocked, isFalse);

      await lock.protectRead(() async => expect(lock.isLocked, isTrue));

      var lock2 = await lockService.getLock("test");
      expect(lock2, same(lock));

      var lock3 = await lockService.getLock("test2");
      expect(lock3, isNot(same(lock2)));
    });
  });
}
