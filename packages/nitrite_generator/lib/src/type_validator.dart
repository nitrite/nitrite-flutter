import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:source_gen/source_gen.dart';

class TypeValidator extends TypeVisitor {
  final Element _element;

  TypeValidator(this._element);

  @override
  visitDynamicType(DynamicType type) {
    throw InvalidGenerationSourceError(
        'dynamic type is not supported for automatic '
        'converter code generation.',
        element: _element);
  }

  @override
  visitFunctionType(FunctionType type) {}

  @override
  visitInterfaceType(InterfaceType type) {
    for (var arg in type.typeArguments) {
      if (arg.isDartCoreIterable ||
          arg.isDartCoreMap ||
          arg.isDartCoreList ||
          arg.isDartCoreSet) {
        throw InvalidGenerationSourceError(
            'Nested collection is not supported for automatic '
            'converter code generation.',
            element: _element);
      }

      if (arg.isDartCoreFunction) {
        throw InvalidGenerationSourceError(
            'Function type is not supported for automatic '
            'converter code generation.',
            element: _element);
      }

      if (arg.isDartCoreSymbol) {
        throw InvalidGenerationSourceError(
            'Symbol type is not supported for automatic '
            'converter code generation.',
            element: _element);
      }
    }
  }

  @override
  visitNeverType(NeverType type) {
    throw InvalidGenerationSourceError(
        'Never type is not supported for automatic '
        'converter code generation.');
  }

  @override
  visitRecordType(RecordType type) {}

  @override
  visitTypeParameterType(TypeParameterType type) {}

  @override
  visitVoidType(VoidType type) {
    throw InvalidGenerationSourceError(
        'Void type is not supported for automatic '
        'converter code generation.');
  }

  @override
  visitInvalidType(InvalidType type) {
    throw InvalidGenerationSourceError(
        'Invalid type is not supported for automatic '
        'converter code generation.');
  }
}
