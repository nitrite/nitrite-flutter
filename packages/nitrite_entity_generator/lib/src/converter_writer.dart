import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_builder/code_builder.dart';
import 'package:nitrite_entity_generator/src/common.dart';
import 'package:nitrite_entity_generator/src/type_checker.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

class ConverterWriter {
  final ConverterInfo _converterInfo;

  ConverterWriter(this._converterInfo);

  Class write() {
    return Class((builder) {
      builder
        ..name = '${_converterInfo.converterName}'
        ..extend = refer('EntityConverter<${_converterInfo.className}>')
        ..methods.add(_generateFromDocument())
        ..methods.add(_generateToDocument());
    });
  }

  Method _generateFromDocument() {
    return Method((builder) {
      builder
        ..name = 'fromDocument'
        ..annotations.add(refer('override'))
        ..lambda = false
        ..returns = refer('${_converterInfo.className}')
        ..requiredParameters.add(Parameter((builder) {
          builder
            ..name = 'document'
            ..type = refer('Document');
        }))
        ..requiredParameters.add(Parameter((builder) {
          builder
            ..name = 'nitriteMapper'
            ..type = refer('NitriteMapper');
        }))
        ..body = Code('${_generateFromDocumentBody()}');
    });
  }

  Method _generateToDocument() {
    return Method((builder) {
      builder
        ..name = 'toDocument'
        ..annotations.add(refer('override'))
        ..lambda = false
        ..returns = refer('Document')
        ..requiredParameters.add(Parameter((builder) {
          builder
            ..name = 'entity'
            ..type = refer('${_converterInfo.className}');
        }))
        ..requiredParameters.add(Parameter((builder) {
          builder
            ..name = 'nitriteMapper'
            ..type = refer('NitriteMapper');
        }))
        ..body = Code('${_generateToDocumentBody()}');
    });
  }

  String _generateFromDocumentBody() {
    StringBuffer buffer = StringBuffer();

    var ctorInfo = _converterInfo.constructorInfo;
    var fieldInfos = _converterInfo.fieldInfoList;

    bool hasDefaultCtor = ctorInfo.hasDefaultCtor;
    bool hasAllOptionalNoFinalParams = ctorInfo.hasAllOptionalPositionalCtor &&
        fieldInfos.every((f) => !f.isFinal);

    bool hasAllNamedAllFinalParams = ctorInfo.hasAllOptionalNamedCtor &&
        fieldInfos.every((f) => f.isFinal) &&
        UnorderedIterableEquality()
            .equals(fieldInfos.map((e) => e.fieldName), ctorInfo.ctorParamNames);

    if (hasDefaultCtor || hasAllOptionalNoFinalParams) {
      _generateFieldMapping(buffer);
    } else if (hasAllNamedAllFinalParams) {
      _generateAllFinalFieldMapping(buffer);
    } else {
      if (!UnorderedIterableEquality()
          .equals(fieldInfos.map((e) => e.fieldName), ctorInfo.ctorParamNames)) {
        throw InvalidGenerationSourceError(
            'Constructor parameters do not match with the fields of the class.');
      }

      if (!hasAllNamedAllFinalParams) {
        throw InvalidGenerationSourceError(
            'All fields of the class must be all final or all non-final.');
      }

      if (!hasAllOptionalNoFinalParams) {
        throw InvalidGenerationSourceError(
            'All fields of the class must be all final or all non-final.');
      }

      throw InvalidGenerationSourceError(
          '`@Converter` can only be used on classes which has at least one '
          'public constructor which is either a default constructor or '
          'one with all named arguments.');
    }

    buffer.writeln('return entity;');

    return buffer.toString();
  }

  void _generateFieldMapping(StringBuffer buffer) {
    buffer.writeln('var entity = ${_converterInfo.className}();');
    for (var fieldInfo in _converterInfo.fieldInfoList) {
      buffer.write('entity.${fieldInfo.fieldName} = ');
      _generatePropertyMapping(fieldInfo, buffer);
    }
  }

  void _generateAllFinalFieldMapping(StringBuffer buffer) {
    buffer.writeln('var entity = ${_converterInfo.className}(');
    for (var fieldInfo in _converterInfo.fieldInfoList) {
      buffer.write('${fieldInfo.fieldName}: ');
      _generatePropertyMapping(fieldInfo, buffer);
    }
    buffer.writeln(');');
  }

  void _generatePropertyMapping(FieldInfo fieldInfo, StringBuffer buffer) {
    var propertyName = fieldInfo.fieldName;
    if (fieldInfo.aliasName.isNotEmpty) {
      propertyName = fieldInfo.aliasName;
    }

    var fieldType = fieldInfo.fieldType;
    if (isBuiltin(fieldType)) {
      buffer.writeln("document['$propertyName'];");
    } else {
      if (fieldType.isDartCoreList) {
        buffer.writeln("EntityConverter."
            "toList(document['$propertyName'], nitriteMapper);");
      } else if (fieldType.isDartCoreIterable) {
        buffer.writeln("EntityConverter."
            "toIterable(document['$propertyName'], nitriteMapper);");
      } else if (fieldType.isDartCoreSet) {
        buffer.writeln("EntityConverter."
            "toSet(document['$propertyName'], nitriteMapper);");
      } else if (fieldType.isDartCoreMap) {
        buffer.writeln("EntityConverter."
            "toMap(document['$propertyName'], nitriteMapper);");
      } else {
        buffer.write('nitriteMapper.convert<');
        buffer.write(
            '${fieldInfo.fieldType.getDisplayString(withNullability: true)}');
        buffer.write(', Document>(');
        buffer.write("document['$propertyName'])");

        if (fieldInfo.fieldType.nullabilitySuffix == NullabilitySuffix.none) {
          buffer.writeln('!;');
        } else {
          buffer.writeln(';');
        }
      }
    }
  }

  String _generateToDocumentBody() {
    StringBuffer buffer = StringBuffer();

    buffer.writeln('var document = emptyDocument();');

    for (var fieldInfo in _converterInfo.fieldInfoList) {
      var propertyName = fieldInfo.fieldName;
      if (fieldInfo.aliasName.isNotEmpty) {
        propertyName = fieldInfo.aliasName;
      }

      var fieldType = fieldInfo.fieldType;

      if (isBuiltin(fieldType)) {
        buffer.writeln(
            "document.put('$propertyName', entity.${fieldInfo.fieldName});");
      } else {
        if (fieldType.isDartCoreList) {
          buffer.writeln("document.put('$propertyName', EntityConverter."
              "fromList(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreIterable) {
          buffer.writeln("document.put('$propertyName', EntityConverter."
              "fromIterable(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreSet) {
          buffer.writeln("document.put('$propertyName', EntityConverter."
              "fromSet(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreMap) {
          buffer.writeln("document.put('$propertyName', EntityConverter."
              "fromMap(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else {
          buffer.write("document.put('$propertyName', ");
          buffer.write('nitriteMapper.convert<Document, ');
          buffer.write(
              '${fieldInfo.fieldType.getDisplayString(withNullability: true)}');
          buffer.writeln('>(entity.${fieldInfo.fieldName}));');
        }
      }
    }

    buffer.writeln('return document;');

    return buffer.toString();
  }
}
