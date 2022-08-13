import 'package:analyzer/dart/element/type.dart';
import 'package:nitrite/nitrite.dart';
import 'package:source_gen/source_gen.dart';


TypeChecker typeChecker(final Type type) => TypeChecker.fromRuntime(type);

final isMappable = typeChecker(Mappable);

final isString = typeChecker(String);

final isInt = typeChecker(int);

final isDouble = typeChecker(double);

final isNum = typeChecker(num);

final isDateTime = typeChecker(DateTime);

final isDuration = typeChecker(Duration);

final isBool = typeChecker(bool);

bool isBuiltin(DartType type) {
  if (isString.isExactlyType(type)) return true;
  if (isInt.isExactlyType(type)) return true;
  if (isDouble.isExactlyType(type)) return true;
  if (isNum.isExactlyType(type)) return true;
  if (isBool.isExactlyType(type)) return true;
  if (isDateTime.isExactlyType(type)) return true;
  if (isDuration.isExactlyType(type)) return true;

  return false;
}