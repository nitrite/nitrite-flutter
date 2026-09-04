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
    // Copy, never adopt. `cast<String>()` hands back a view onto the set held in
    // the catalog document, so adding a name here would edit the stored set in
    // place - a write that has not been made yet, and one no rollback undoes.
    var stored = document[tagMapMetaData]?.cast<String>();
    _mapNames = stored == null
        ? HashSet<String>()
        : HashSet<String>.from(stored);
  }

  @override
  Document getInfo() {
    return createDocument(tagMapMetaData, _mapNames);
  }
}
