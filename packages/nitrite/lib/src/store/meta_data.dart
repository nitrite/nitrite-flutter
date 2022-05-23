import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/constants.dart';

abstract class MetaData {
  Document getInfo();
}

class MapMetaData implements MetaData {
  late Set<String> _mapNames;

  Set<String> get mapNames => _mapNames;

  MapMetaData(Document document) {
    var mapNames = document.get<Set<String>?>(Constants.tagMapMetaData);
    mapNames ??= HashSet<String>();
    _mapNames = mapNames;
  }

  @override
  Document getInfo() {
    return Document.createDocument(Constants.tagMapMetaData, _mapNames);
  }
}
