import 'package:nitrite/nitrite.dart';

/// The nitrite database metadata.
class StoreMetaData implements MetaData {
  late int createTime;
  late String storeVersion;
  late String nitriteVersion;
  late int schemaVersion;

  StoreMetaData(Document document) {
    createTime = document.get('createTime');
    storeVersion = document.get('storeVersion');
    nitriteVersion = document.get('nitriteVersion');
    schemaVersion = document.get('schemaVersion');
  }

  /// Gets the database info in a document.
  @override
  Document getInfo() {
    return Document.emptyDocument()
      ..put('createTime', createTime)
      ..put('storeVersion', storeVersion)
      ..put('nitriteVersion', nitriteVersion)
      ..put('schemaVersion', schemaVersion);
  }
}
