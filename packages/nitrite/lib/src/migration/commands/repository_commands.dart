import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/migration/commands/collection_commands.dart';
import 'package:nitrite/src/migration/commands/commands.dart';

class RepositoryRenameCommand extends CollectionRenameCommand {
  RepositoryRenameCommand(Quartet<String, String?, String, String?> arguments)
      : super(Pair(
            findRepositoryNameByTypeName(arguments.first, arguments.second),
            findRepositoryNameByTypeName(arguments.third, arguments.fourth)));
}

class ChangeDataTypeCommand extends BaseCommand {
  final Quartet<String, String?, String, TypeConverter> _arguments;

  ChangeDataTypeCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var repositoryName =
        findRepositoryNameByTypeName(_arguments.first, _arguments.second);
    var fieldName = _arguments.third;
    TypeConverter typeConverter = _arguments.fourth;

    await initialize(nitrite, repositoryName);

    var futures = <Future<void>>[];
    await for (var pair in nitriteMap!.entries()) {
      var document = pair.second;
      var value = document.get(fieldName);
      var newValue = typeConverter(value);
      document.put(fieldName, newValue);

      futures.add(nitriteMap!.put(pair.first, document));
    }
    await Future.wait(futures);

    var indexDescriptor =
        await operations?.findIndex(Fields.withNames([fieldName]));
    if (indexDescriptor != null) {
      await operations?.rebuildIndex(indexDescriptor);
    }
  }
}

class ChangeIdFieldCommand extends BaseCommand {
  final Quartet<String, String?, Fields, Fields> _arguments;

  ChangeIdFieldCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) async {
    var repositoryName =
        findRepositoryNameByTypeName(_arguments.first, _arguments.second);
    var oldFields = _arguments.third;
    var newFields = _arguments.fourth;

    await initialize(nitrite, repositoryName);

    var hasIndex = await operations?.hasIndex(oldFields);
    if (hasIndex!) {
      await operations?.dropIndex(oldFields);
    }

    await operations?.createIndex(newFields, IndexType.unique);
  }
}
