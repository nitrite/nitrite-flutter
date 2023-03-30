// ignore_for_file: implementation_imports

import 'package:hive/src/hive_impl.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite_hive_adapter/src/adapters/dbvalue_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/document_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/fields_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/nitrite_id_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/set_adapter.dart';
import 'package:nitrite_hive_adapter/src/store/hive_module.dart';

Future<HiveImpl> openHiveDb(HiveConfig hiveConfig) async {
  var hive = HiveImpl();

  // initialize with file path and backend preference
  hive.init(hiveConfig.filePath,
      backendPreference: hiveConfig.backendPreference);

  // register built-in adapters
  _registerBuiltinTypeAdapters(hive);

  // register user adapters (if any)
  hiveConfig.typeAdapters.forEach(hive.registerAdapter);
  return hive;
}

void _registerBuiltinTypeAdapters(HiveImpl hive) {
  hive.registerAdapter(DocumentAdapter());
  hive.registerAdapter(NitriteIdAdapter());
  hive.registerAdapter(SetAdapter());
  hive.registerAdapter(DBValueAdapter());
  hive.registerAdapter(FieldsAdapter());
}

int nitriteKeyComparator(dynamic k1, dynamic k2) {
  if (k1 is Comparable && k2 is Comparable) {
    return compare(k1, k2);
  } else {
    return 1;
  }
}
