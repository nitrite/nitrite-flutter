import 'package:nitrite/src/common/concurrent/lock_service.dart';
import 'package:nitrite/src/nitrite_database.dart';

class Session {
  Session(NitriteDatabase nitriteDatabase, LockService lockService);
}
