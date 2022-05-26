import 'package:nitrite/src/collection/document.dart';
import 'package:nitrite/src/collection/nitrite_id.dart';
import 'package:nitrite/src/common/concurrent/lock_service.dart';
import 'package:nitrite/src/nitrite_config.dart';
import 'package:nitrite/src/store/nitrite_map.dart';

abstract class NitriteCollection {
  bool get isDropped;
  bool get isOpen;
  Future<void> close();

  static create(String name, NitriteMap<NitriteId, Document> nitriteMap, NitriteConfig nitriteConfig, LockService lockService) {}

  find() {}
  update(dynamic filter, dynamic doc, dynamic option);
}
