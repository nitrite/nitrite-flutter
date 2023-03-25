import 'dart:collection';

import 'package:nitrite/nitrite.dart';

abstract class MetaData {
  Document getInfo();
}

class MapMetaData implements MetaData {
  late Set<String> _mapNames;

  Set<String> get mapNames => _mapNames;

  MapMetaData(Document document) {
    var mapNames = document[tagMapMetaData]?.cast<String>();
    mapNames ??= HashSet<String>();
    _mapNames = mapNames;
  }

  @override
  Document getInfo() {
    return Document.createDocument(tagMapMetaData, _mapNames);
  }
}
