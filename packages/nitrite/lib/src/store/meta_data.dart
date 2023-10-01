import 'dart:collection';

import 'package:nitrite/nitrite.dart';

/// @nodoc
abstract class MetaData {
  Document getInfo();
}

/// @nodoc
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
    return createDocument(tagMapMetaData, _mapNames);
  }
}
