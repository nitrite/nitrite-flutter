import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/migration/commands/commands.dart';
import 'package:nitrite/src/store/user_auth_service.dart';

class AddPasswordCommand extends Command {
  final Pair<String, String> _arguments;

  AddPasswordCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) {
    var authService = UserAuthenticationService(nitrite.getStore());
    return authService.addOrUpdatePassword(
        false, _arguments.first, "", _arguments.second);
  }
}

class ChangePasswordCommand extends Command {
  final Triplet<String, String, String> _arguments;

  ChangePasswordCommand(this._arguments);

  @override
  Future<void> execute(Nitrite nitrite) {
    var authService = UserAuthenticationService(nitrite.getStore());
    return authService.addOrUpdatePassword(
        true, _arguments.first, _arguments.second, _arguments.third);
  }
}

class DropCollectionCommand extends BaseCommand {
  final String _collectionName;

  DropCollectionCommand(this._collectionName);

  @override
  Future<void> execute(Nitrite nitrite) async {
    await initialize(nitrite, _collectionName);

    await operations?.dropCollection();
  }
}

class DropRepositoryCommand extends DropCollectionCommand {
  DropRepositoryCommand(Pair<String, String?> arguments)
      : super(findRepositoryNameByTypeName(arguments.first, arguments.second));
}

class CustomCommand extends Command {
  final CustomInstruction _instruction;

  CustomCommand(this._instruction);

  @override
  Future<void> execute(Nitrite nitrite) {
    return _instruction(nitrite);
  }
}
