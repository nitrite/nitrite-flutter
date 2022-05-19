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
}
