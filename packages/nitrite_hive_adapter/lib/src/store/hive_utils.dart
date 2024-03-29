// ignore_for_file: implementation_imports

import 'package:hive/src/hive_impl.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite_hive_adapter/src/adapters/datetime_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/dbvalue_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/document_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/fields_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/nitrite_id_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/set_adapter.dart';
import 'package:nitrite_hive_adapter/src/adapters/spatial_adapters.dart';
import 'package:nitrite_hive_adapter/src/store/hive_module.dart';

/// @nodoc
Future<HiveImpl> openHiveDb(HiveConfig hiveConfig) async {
  var hive = HiveImpl();

  // initialize with file path and backend preference
  hive.init(hiveConfig.filePath,
      backendPreference: hiveConfig.backendPreference);

  // register built-in adapters
  _registerBuiltinTypeAdapters(hive);

  // register user adapters (if any)
  for (var register in hiveConfig.typeAdapterRegistry) {
    register(hive);
  }
  return hive;
}

void _registerBuiltinTypeAdapters(HiveImpl hive) {
  hive.registerAdapter(NitriteIdAdapter());
  hive.registerAdapter(DocumentAdapter());
  hive.registerAdapter(SetAdapter());
  hive.registerAdapter(DBValueAdapter());
  hive.registerAdapter(DBNullAdapter());
  hive.registerAdapter(FieldsAdapter());
  hive.registerAdapter(DateTimeAdapter(), internal: true);
  hive.registerAdapter(SpatialKeyAdapter());
  hive.registerAdapter(BoundingBoxAdapter());
}

/// @nodoc
int nitriteKeyComparator(dynamic k1, dynamic k2) {
  if (k1 is Comparable && k2 is Comparable) {
    return compare(k1, k2);
  }
  return 1;
}
