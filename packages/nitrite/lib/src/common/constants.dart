import 'package:nitrite/src/store/memory/in_memory_meta.dart';

const String indexMetaPrefix = "\$nitrite_index_meta";

const String indexPrefix = "\$nitrite_index";

const String internalNameSeparator = "|";

const String userMap = "\$nitrite_users";

const String objectStoreNameSeparator = ":";

const String metaMapName = "\$nitrite_meta_map";

const String storeInfo = "\$nitrite_store_info";

const String collectionCatalog = "\$nitrite_catalog";

const String keyObjSeparator = "+";

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

const int initialSchemaVersion = 1;

const String no2 = "NO\u2082";

const String idPrefix = "[";

const String idSuffix = "]$no2";

const String tagCollections = "collections";

const String tagRepositories = "repositories";

const String tagKeyedRepositories = "keyed-repositories";

const String tagType = "type";

const String tagIndices = "indices";

const String tagIndex = "index";

const String tagIndexType = "indexType";

const String tagIndexFields = "indexFields";

const String tagData = "data";

const String tagName = "name";

const String tagKey = "key";

const String tagValue = "value";

const String docId = "_id";

const String docRevision = "_revision";

const String docModified = "_modified";

const String docSource = "_source";

const String tagMapMetaData = "mapNames";

const String replicator = "Replicator.$no2";

const String typeId = "typeId";

String nitriteVersion = meta["version"]!;
