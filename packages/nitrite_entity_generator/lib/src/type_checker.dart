import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

TypeChecker typeChecker(final Type type) => TypeChecker.fromRuntime(type);

final isString = typeChecker(String);

final isRunes = typeChecker(Runes);

final isInt = typeChecker(int);

final isDouble = typeChecker(double);

final isNum = typeChecker(num);

final isDateTime = typeChecker(DateTime);

final isDuration = typeChecker(Duration);

final isBool = typeChecker(bool);

final isSymbol = typeChecker(Symbol);

bool isBuiltin(DartType type) {
  if (isNum.isExactlyType(type)) return true;
  if (isInt.isExactlyType(type)) return true;
  if (isDouble.isExactlyType(type)) return true;
  if (isString.isExactlyType(type)) return true;
  if (isRunes.isExactlyType(type)) return true;
  if (isBool.isExactlyType(type)) return true;
  if (isNum.isExactlyType(type)) return true;
  if (isDateTime.isExactlyType(type)) return true;
  if (isDuration.isExactlyType(type)) return true;
  if (isSymbol.isExactlyType(type)) return true;

  return false;
}
