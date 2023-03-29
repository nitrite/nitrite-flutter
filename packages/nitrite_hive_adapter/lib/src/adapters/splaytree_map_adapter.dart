import 'dart:collection';

import 'package:hive/hive.dart';

class SplayTreeMapAdapter extends TypeAdapter<SplayTreeMap> {
  @override
  int get typeId => 9;

  @override
  SplayTreeMap read(BinaryReader reader) {
    var list = reader.readList() as List<MapEntry<dynamic, dynamic>>;
    var splayTreeMap = SplayTreeMap();
    splayTreeMap.addEntries(list);
    return splayTreeMap;
  }

  @override
  void write(BinaryWriter writer, SplayTreeMap obj) {
    var entries = obj.entries.toList();
    writer.writeList(entries);
  }
}
