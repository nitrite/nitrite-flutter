import 'package:nitrite/nitrite.dart';

/// A rudimentary parallel task executor.
class Executor {
  final List<Future<void>> _futures = [];
  bool _disposed = false;

  /// Submits a task which returns a future and which will be
  /// executed later.
  ///
  /// NOTE: if the [execute] method is called already, new
  /// task cannot be submitted.
  void submit(Future<void> Function() computation) {
    if (!_disposed) {
      _futures.add(computation());
    } else {
      throw InvalidOperationException('Executor is already disposed');
    }
  }

  /// Runs all submitted tasks in parallel and wait for
  /// the completion of all tasks.
  ///
  /// NOTE: once this methods run, new tasks cannot be
  /// submitted to this executor.
  Future<void> execute() async {
    await Future.wait(_futures, eagerError: true);
    _disposed = true;
  }
}
