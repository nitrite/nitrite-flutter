import 'package:nitrite/src/common/async/executor.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../test_utils.dart';

void main() {
  group('Executor Test Suite', () {
    test('Test Execute', () async {
      var executor = Executor();
      var list = <int>[];

      executor.submit(() async {
        await Future.delayed(Duration(seconds: 1), () => list.add(1));
        await Future.delayed(Duration(seconds: 1), () => list.add(2));
      });

      executor.submit(() async {
        await Future.delayed(Duration(seconds: 1), () => list.add(3));
        await Future.delayed(Duration(seconds: 1), () => list.add(4));
      });

      await executor.execute();

      expect(list, [1, 3, 2, 4]);

      list = <int>[];
      executor = Executor();
      executor.submit(
          () => Future.delayed(Duration(seconds: 1), () => list.add(1)));
      executor.submit(
          () => Future.delayed(Duration(seconds: 1), () => list.add(2)));
      executor.submit(
          () => Future.delayed(Duration(seconds: 1), () => list.add(3)));
      executor.submit(
          () => Future.delayed(Duration(seconds: 1), () => list.add(4)));

      await executor.execute();
      expect(list, [1, 2, 3, 4]);
    });

    test('Test Parallel Execution', () async {
      var executor = Executor();

      executor.submit(() async {
        await Future.delayed(Duration(seconds: 1), () => print(1));
        await Future.delayed(Duration(seconds: 1), () => print(2));
      });

      executor.submit(() async {
        await Future.delayed(Duration(seconds: 1), () => print(3));
        await Future.delayed(Duration(seconds: 1), () => print(4));
      });

      var stopWatch = Stopwatch();
      stopWatch.start();
      await executor.execute();
      stopWatch.stop();

      expect(stopWatch.elapsed, lessThanOrEqualTo(Duration(seconds: 3)));

      executor = Executor();
      executor
          .submit(() => Future.delayed(Duration(seconds: 1), () => print(1)));
      executor
          .submit(() => Future.delayed(Duration(seconds: 1), () => print(2)));
      executor
          .submit(() => Future.delayed(Duration(seconds: 1), () => print(3)));
      executor
          .submit(() => Future.delayed(Duration(seconds: 1), () => print(4)));

      stopWatch = Stopwatch();
      stopWatch.start();
      await executor.execute();
      stopWatch.stop();

      expect(stopWatch.elapsed, lessThanOrEqualTo(Duration(seconds: 2)));
    });

    test('Test Dispose', () async {
      var executor = Executor();
      executor
          .submit(() => Future.delayed(Duration(seconds: 1), () => print(1)));
      executor
          .submit(() => Future.delayed(Duration(seconds: 1), () => print(2)));
      await executor.execute();

      expect(
          () => executor.submit(
              () => Future.delayed(Duration(seconds: 1), () => print(3))),
          throwsInvalidOperationException);
    });
  });
}
