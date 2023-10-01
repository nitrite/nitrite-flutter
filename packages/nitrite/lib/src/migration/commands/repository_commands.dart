import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/migration/commands/collection_commands.dart';
import 'package:nitrite/src/migration/commands/commands.dart';

/// @nodoc
class RepositoryRenameCommand extends CollectionRenameCommand {
  RepositoryRenameCommand((String, String?, String, String?) arguments)
      : super((
          findRepositoryNameByTypeName(arguments.$1, arguments.$2),
          findRepositoryNameByTypeName(arguments.$3, arguments.$4)
        ));
}

/// @nodoc
class ChangeDataTypeCommand extends BaseCommand {
  final (String, String?, String, TypeConverter) _arguments;

  ChangeDataTypeCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var repositoryName =
        findRepositoryNameByTypeName(_arguments.$1, _arguments.$2);
    var fieldName = _arguments.$3;
    TypeConverter typeConverter = _arguments.$4;

    await initialize(nitrite, repositoryName);

    await for (var pair in nitriteMap!.entries()) {
      var document = pair.$2;
      var value = document.get(fieldName);
      var newValue = typeConverter(value);
      document.put(fieldName, newValue);

      await nitriteMap!.put(pair.$1, document);
    }

    var indexDescriptor =
        await operations?.findIndex(Fields.withNames([fieldName]));
    if (indexDescriptor != null) {
      await operations?.rebuildIndex(indexDescriptor);
    }
  }
}

/// @nodoc
class ChangeIdFieldCommand extends BaseCommand {
  final (String, String?, Fields, Fields) _arguments;

  ChangeIdFieldCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var repositoryName =
        findRepositoryNameByTypeName(_arguments.$1, _arguments.$2);
    var oldFields = _arguments.$3;
    var newFields = _arguments.$4;

    await initialize(nitrite, repositoryName);

    var hasIndex = await operations?.hasIndex(oldFields);
    if (hasIndex!) {
      await operations?.dropIndex(oldFields);
    }

    await operations?.createIndex(newFields, IndexType.unique);
  }
}
