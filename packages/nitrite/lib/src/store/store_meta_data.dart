import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/store/meta_data.dart';

/// @nodoc
class StoreMetaData implements MetaData {
  int? createTime;
  String? storeVersion;
  String? nitriteVersion;
  int? schemaVersion;

  StoreMetaData();

  factory StoreMetaData.fromDocument(Document document) {
    return StoreMetaData()
      ..createTime = document.get('createTime')
      ..storeVersion = document.get('storeVersion')
      ..nitriteVersion = document.get('nitriteVersion')
      ..schemaVersion = document.get('schemaVersion');
  }

  @override
  Document getInfo() {
    return emptyDocument()
      ..put('createTime', createTime)
      ..put('storeVersion', storeVersion)
      ..put('nitriteVersion', nitriteVersion)
      ..put('schemaVersion', schemaVersion);
  }
}
