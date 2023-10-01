import 'package:nitrite/src/store/memory/in_memory_meta.dart';

/// @nodoc
const String indexMetaPrefix = "\$nitrite_index_meta";

/// @nodoc
const String indexPrefix = "\$nitrite_index";

/// @nodoc
const String internalNameSeparator = "|";

/// @nodoc
const String userMap = "\$nitrite_users";

/// @nodoc
const String objectStoreNameSeparator = ":";

/// @nodoc
const String metaMapName = "\$nitrite_meta_map";

/// @nodoc
const String storeInfo = "\$nitrite_store_info";

/// @nodoc
const String collectionCatalog = "\$nitrite_catalog";

/// @nodoc
const String keyObjSeparator = "+";

/// @nodoc
const List<String> reservedNames = <String>[
  indexMetaPrefix,
  indexPrefix,
  internalNameSeparator,
  userMap,
  objectStoreNameSeparator,
  metaMapName,
  storeInfo,
  collectionCatalog,
  keyObjSeparator
];

/// The initial schema version of Nitrite database.
const int initialSchemaVersion = 1;

/// @nodoc
const String no2 = "NO\u2082";

/// @nodoc
const String idPrefix = "[";

/// @nodoc
const String idSuffix = "]$no2";

/// @nodoc
const String tagCollections = "collections";

/// @nodoc
const String tagRepositories = "repositories";

/// @nodoc
const String tagKeyedRepositories = "keyed-repositories";

/// @nodoc
const String tagType = "type";

/// @nodoc
const String tagIndices = "indices";

/// @nodoc
const String tagIndex = "index";

/// @nodoc
const String tagIndexType = "indexType";

/// @nodoc
const String tagIndexFields = "indexFields";

/// @nodoc
const String tagData = "data";

/// @nodoc
const String tagName = "name";

/// @nodoc
const String tagKey = "key";

/// @nodoc
const String tagValue = "value";

/// @nodoc
const String docId = "_id";

/// @nodoc
const String docRevision = "_revision";

/// @nodoc
const String docModified = "_modified";

/// @nodoc
const String docSource = "_source";

/// @nodoc
const String tagMapMetaData = "mapNames";

/// @nodoc
const String replicator = "Replicator.$no2";

/// @nodoc
const String typeId = "typeId";

/// @nodoc
String nitriteVersion = meta["version"]!;
