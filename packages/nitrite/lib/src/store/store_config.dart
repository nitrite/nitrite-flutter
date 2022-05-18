import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

abstract class StoreConfig {
  String get filePath;

  bool get isReadOnly;

  void addStoreEventListener(StoreEventListener listener);

  bool get isInMemory => filePath.isNullOrEmpty;
}
