// TODO: Put public facing types in this file.

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/constants.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// Checks if you are awesome. Spoiler: you are.
abstract class Nitrite {
  static NitriteBuilder builder() {
    return NitriteBuilder();
  }

  void commit();

  NitriteCollection getCollection(String name);

  ObjectRepository<T> getRepository<T>([String? key]);

  void destroyCollection(String name);

  void destroyRepository<T>([String? key]);

  Set<String> get listCollectionNames;

  Set<String> get listRepositories;

  Map<String, Set<String>> get listKeyedRepositories;

  bool get hasUnsavedChanges;

  bool get isClosed;

  void close();

  NitriteConfig get getConfig;

  NitriteStore<T> getStore<T>();

  StoreMetaData get getDatabaseMetaData;

  Session createSession();

  bool hasCollection(String name) {
    checkOpened();
    return listCollectionNames.contains(name);
  }

  bool hasRepository<T>([String? key]) {
    checkOpened();
    if (key.isNullOrEmpty) {
      return listRepositories.contains(T.toString());
    } else {
      return listKeyedRepositories.containsKey(key) &&
          listKeyedRepositories[key]?.contains(T.toString()) != null;
    }
  }

  void validateCollectionName(String name) {
    name.notNullOrEmpty("name cannot be null or empty");

    for (String reservedName in Constants.RESERVED_NAMES) {
      if (name.contains(reservedName)) {
        throw ValidationException("name cannot contain $reservedName");
      }
    }
  }

  void checkOpened() {
    if (getStore().isClosed) {
      throw NitriteIOException("Nitrite is closed");
    }
  }
}
