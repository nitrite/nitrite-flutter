import 'package:mutex/mutex.dart';

class LockService {
  final Map<String, ReadWriteMutex> _lockRegistry = {};
  static final Mutex _lock = Mutex();

  LockService();

  Future<ReadWriteMutex> getLock(String key) async {
    return await _lock.protect(() async {
      if (_lockRegistry.containsKey(key)) {
        return _lockRegistry[key]!;
      }
      _lockRegistry[key] = ReadWriteMutex();
      return _lockRegistry[key]!;
    });
  }
}
