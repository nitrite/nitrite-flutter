class Constants {
  static const String indexMetaPrefix = "\$nitrite_index_meta";

  static const String indexPrefix = "\$nitrite_index";

  static const String internalNameSeparator = "|";

  static const String userMap = "\$nitrite_users";

  static const String objectStoreNameSeparator = ":";

  static const String metaMapName = "\$nitrite_meta_map";

  static const String storeInfo = "\$nitrite_store_info";

  static const String collectionCatalog = "\$nitrite_catalog";

  static const String keyObjSeparator = "+";

  static const List<String> reservedNames = <String>[
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

  static final int initialSchemaVersion = 1;

  static final String no2 = "NO\u2082";

  static final String idPrefix = "[";

  static final String idSuffix = "]$no2";

  static final String tagCollections = "collections";

  static final String tagRepositories = "repositories";

  static final String tagKeyedRepositories = "keyed-repositories";

  static final String tagType = "type";

  static final String tagIndices = "indices";

  static final String tagIndex = "index";

  static final String tagData = "data";

  static final String tagName = "name";

  static final String tagKey = "key";

  static final String tagValue = "value";

  static final String docId = "_id";

  static final String docRevision = "_revision";

  static final String docModified = "_modified";

  static final String docSource = "_source";

  static final String tagMapMetaData = "mapNames";
}
