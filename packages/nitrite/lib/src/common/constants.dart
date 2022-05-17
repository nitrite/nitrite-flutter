class Constants {
  static const String INDEX_META_PREFIX = "\$nitrite_index_meta";

  static const String INDEX_PREFIX = "\$nitrite_index";

  static const String INTERNAL_NAME_SEPARATOR = "|";

  static const String USER_MAP = "\$nitrite_users";

  static const String OBJECT_STORE_NAME_SEPARATOR = ":";

  static const String META_MAP_NAME = "\$nitrite_meta_map";

  static const String STORE_INFO = "\$nitrite_store_info";

  static const String COLLECTION_CATALOG = "\$nitrite_catalog";

  static const String KEY_OBJ_SEPARATOR = "+";

  static const List<String> RESERVED_NAMES = <String>[
    INDEX_META_PREFIX,
    INDEX_PREFIX,
    INTERNAL_NAME_SEPARATOR,
    USER_MAP,
    OBJECT_STORE_NAME_SEPARATOR,
    META_MAP_NAME,
    STORE_INFO,
    COLLECTION_CATALOG,
    KEY_OBJ_SEPARATOR
  ];
}
