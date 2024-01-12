/// Nitrite is a lightweight, embedded, and self-contained NoSQL database.
/// It provides an easy-to-use API to store and retrieve data. Nitrite stores
/// data in the form of documents and supports indexing on fields within
/// the documents to provide efficient search capabilities. Nitrite supports
/// transactions, and provides a simple and efficient way to persist data.
///
/// Nitrite is designed to be embedded within the application
/// and does not require any external setup or installation.
///
/// This library provides a Dart implementation of Nitrite.
library nitrite;

export 'src/nitrite_base.dart';
export 'src/nitrite_builder.dart';
export 'src/nitrite_config.dart';

export 'src/collection/index.dart' hide EventAware;
export 'src/common/index.dart';
export 'src/exception/exceptions.dart';
export 'src/store/index.dart';
export 'src/filters/index.dart';
export 'src/index/index.dart';
export 'src/migration/index.dart';
export 'src/transaction/index.dart';

// ignore: invalid_export_of_internal_element
export 'src/repository/index.dart';
