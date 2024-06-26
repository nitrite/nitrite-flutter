import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_builder/code_builder.dart';
import 'package:nitrite_generator/src/common.dart';
import 'package:nitrite_generator/src/type_checker.dart';
import 'package:source_gen/source_gen.dart';

class ConverterWriter {
  final ConverterInfo _converterInfo;

  ConverterWriter(this._converterInfo);

  Class write() {
    return Class((builder) {
      builder
        ..name = _converterInfo.converterName
        ..extend = refer('EntityConverter<${_converterInfo.className}>')
        ..methods.add(_generateFromDocument())
        ..methods.add(_generateToDocument());
    });
  }

  // fromDocument method builder
  Method _generateFromDocument() {
    return Method((builder) {
      builder
        ..name = 'fromDocument'
        ..annotations.add(refer('override'))
        ..lambda = false
        ..returns = refer(_converterInfo.className)
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
        ..body = Code(_generateFromDocumentBody());
    });
  }

  // toDocument method builder
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
            ..type = refer(_converterInfo.className);
        }))
        ..requiredParameters.add(Parameter((builder) {
          builder
            ..name = 'nitriteMapper'
            ..type = refer('NitriteMapper');
        }))
        ..body = Code(_generateToDocumentBody());
    });
  }

  String _generateFromDocumentBody() {
    StringBuffer buffer = StringBuffer();

    if (_converterInfo.isEnum) {
      buffer.writeln(
          'return ${_converterInfo.className}.values[document[\'index\']];');
      return buffer.toString();
    }

    var ctorInfo = _converterInfo.constructorInfo;

    if (ctorInfo.hasDefaultCtor || ctorInfo.hasAllOptionalPositionalCtor) {
      _generateFieldMapping(buffer);
    } else if (ctorInfo.hasAllOptionalNamedCtor || ctorInfo.hasAllNamedCtor) {
      _generateAllFinalFieldMapping(buffer);
    } else {
      throw InvalidGenerationSourceError(
          '`@Convertable` can only be used on classes which has at least '
          'one public constructor which is either a default constructor or '
          'one with all optional arguments.');
    }

    _generateSetterMapping(buffer);

    buffer.writeln('return entity;');

    return buffer.toString();
  }

  void _generateFieldMapping(StringBuffer buffer) {
    buffer.writeln('var entity = ${_converterInfo.className}();');
    for (var fieldInfo in _converterInfo.fieldInfoList) {
      if (fieldInfo.isIgnored) continue;

      buffer.write('entity.${fieldInfo.fieldName} = ');

      var keyName = fieldInfo.fieldName;
      if (fieldInfo.aliasName.isNotEmpty) {
        keyName = fieldInfo.aliasName;
      }

      var fieldType = fieldInfo.fieldType;
      if (isNitriteId.isExactlyType(fieldType)) {
        // if type is NitriteId handle it specially
        buffer.writeln("document.id;");
      } else if (isBuiltin(fieldType)) {
        if (fieldType.nullabilitySuffix == NullabilitySuffix.none) {
          buffer.write("document['$keyName'] ?? ");
          buffer.writeln("${defaultValue(fieldType)};");
        } else {
          buffer.writeln("document['$keyName'];");
        }
      } else {
        if (fieldType.isDartCoreList) {
          buffer.writeln("EntityConverter."
              "toList(document['$keyName'], nitriteMapper);");
        } else if (fieldType.isDartCoreIterable) {
          buffer.writeln("EntityConverter."
              "toIterable(document['$keyName'], nitriteMapper);");
        } else if (fieldType.isDartCoreSet) {
          buffer.writeln("EntityConverter."
              "toSet(document['$keyName'], nitriteMapper);");
        } else if (fieldType.isDartCoreMap) {
          buffer.writeln("EntityConverter."
              "toMap(document['$keyName'], nitriteMapper);");
        } else {
          buffer.write('nitriteMapper.tryConvert<');
          buffer.write(
              fieldInfo.fieldType.getDisplayString(withNullability: false));
          buffer.write(', Document>(');
          buffer.write("document['$keyName'])");

          if (fieldInfo.fieldType.nullabilitySuffix == NullabilitySuffix.none) {
            buffer.writeln('!;');
          } else {
            buffer.writeln(';');
          }
        }
      }
    }
  }

  void _generateAllFinalFieldMapping(StringBuffer buffer) {
    buffer.writeln('var entity = ${_converterInfo.className}(');
    for (var fieldInfo in _converterInfo.fieldInfoList) {
      if (fieldInfo.isIgnored && fieldInfo.setNull) {
        // if field is ignored, either we can set it null,
        // or don't assign it so it takes the default value
        buffer.write('${fieldInfo.fieldName}: null,');
        continue;
      }

      buffer.write('${fieldInfo.fieldName}: ');

      var keyName = fieldInfo.fieldName;
      if (fieldInfo.aliasName.isNotEmpty) {
        keyName = fieldInfo.aliasName;
      }

      var fieldType = fieldInfo.fieldType;
      if (isNitriteId.isExactlyType(fieldType)) {
        // if type is NitriteId handle it specially
        buffer.writeln("document.id,");
      } else if (isBuiltin(fieldType)) {
        if (fieldType.nullabilitySuffix == NullabilitySuffix.none) {
          buffer.write("document['$keyName'] ?? ");
          buffer.writeln("${defaultValue(fieldType)},");
        } else {
          buffer.writeln("document['$keyName'],");
        }
      } else {
        if (fieldType.isDartCoreList) {
          buffer.writeln("EntityConverter."
              "toList(document['$keyName'], nitriteMapper),");
        } else if (fieldType.isDartCoreIterable) {
          buffer.writeln("EntityConverter."
              "toIterable(document['$keyName'], nitriteMapper),");
        } else if (fieldType.isDartCoreSet) {
          buffer.writeln("EntityConverter."
              "toSet(document['$keyName'], nitriteMapper),");
        } else if (fieldType.isDartCoreMap) {
          buffer.writeln("EntityConverter."
              "toMap(document['$keyName'], nitriteMapper),");
        } else {
          buffer.write('nitriteMapper.tryConvert<');
          buffer.write(
              fieldInfo.fieldType.getDisplayString(withNullability: false));
          buffer.write(', Document>(');
          buffer.write("document['$keyName'])");

          if (fieldInfo.fieldType.nullabilitySuffix == NullabilitySuffix.none) {
            buffer.writeln('!,');
          } else {
            buffer.writeln(',');
          }
        }
      }
    }
    buffer.writeln(');');
  }

  void _generateSetterMapping(StringBuffer buffer) {
    for (var propInfo in _converterInfo.propertyInfoList) {
      if (propInfo.isIgnored) continue;

      buffer.write('entity.${propInfo.setterFieldName} = ');

      var keyName = propInfo.setterFieldName;
      if (propInfo.aliasName.isNotEmpty) {
        keyName = propInfo.aliasName;
      }

      var fieldType = propInfo.fieldType;
      if (isNitriteId.isExactlyType(fieldType)) {
        // if type is NitriteId handle it specially
        buffer.writeln("document.id;");
      } else if (isBuiltin(fieldType)) {
        buffer.writeln("document['$keyName'];");
      } else {
        if (fieldType.isDartCoreList) {
          buffer.writeln("EntityConverter."
              "toList(document['$keyName'], nitriteMapper);");
        } else if (fieldType.isDartCoreIterable) {
          buffer.writeln("EntityConverter."
              "toIterable(document['$keyName'], nitriteMapper);");
        } else if (fieldType.isDartCoreSet) {
          buffer.writeln("EntityConverter."
              "toSet(document['$keyName'], nitriteMapper);");
        } else if (fieldType.isDartCoreMap) {
          buffer.writeln("EntityConverter."
              "toMap(document['$keyName'], nitriteMapper);");
        } else {
          buffer.write('nitriteMapper.tryConvert<');
          buffer.write(
              propInfo.fieldType.getDisplayString(withNullability: false));
          buffer.write(', Document>(');
          buffer.write("document['$keyName'])");

          if (propInfo.fieldType.nullabilitySuffix == NullabilitySuffix.none) {
            buffer.writeln('!;');
          } else {
            buffer.writeln(';');
          }
        }
      }
    }
  }

  String _generateToDocumentBody() {
    StringBuffer buffer = StringBuffer();

    buffer.writeln('var document = emptyDocument();');

    if (_converterInfo.isEnum) {
      buffer.writeln('document.put(\'index\', entity.index);');
      buffer.writeln('return document;');
      return buffer.toString();
    }

    // field mapping
    for (var fieldInfo in _converterInfo.fieldInfoList) {
      if (fieldInfo.isIgnored) continue;

      var keyName = fieldInfo.fieldName;
      if (fieldInfo.aliasName.isNotEmpty) {
        keyName = fieldInfo.aliasName;
      }

      var fieldType = fieldInfo.fieldType;

      if (isNitriteId.isExactlyType(fieldType)) {
        // if type is NitriteId handle it specially
        buffer.writeln("document.put('$keyName', "
            "entity.${fieldInfo.fieldName});");
      } else if (isBuiltin(fieldType)) {
        buffer.writeln(
            "document.put('$keyName', entity.${fieldInfo.fieldName});");
      } else {
        if (fieldType.isDartCoreList) {
          buffer.writeln("document.put('$keyName', EntityConverter."
              "fromList(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreIterable) {
          buffer.writeln("document.put('$keyName', EntityConverter."
              "fromIterable(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreSet) {
          buffer.writeln("document.put('$keyName', EntityConverter."
              "fromSet(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreMap) {
          buffer.writeln("document.put('$keyName', EntityConverter."
              "fromMap(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else {
          buffer.write("document.put('$keyName', ");
          buffer.write('nitriteMapper.tryConvert<Document, ');
          buffer.write(
              fieldInfo.fieldType.getDisplayString(withNullability: false));
          buffer.writeln('>(entity.${fieldInfo.fieldName}));');
        }
      }
    }

    // getter mapping
    for (var propInfo in _converterInfo.propertyInfoList) {
      if (propInfo.isIgnored) continue;

      var keyName = propInfo.getterFieldName;
      if (propInfo.aliasName.isNotEmpty) {
        keyName = propInfo.aliasName;
      }

      var fieldType = propInfo.fieldType;

      if (isNitriteId.isExactlyType(fieldType)) {
        // if type is NitriteId handle it specially
        buffer.writeln("document.put('$keyName', "
            "entity.${propInfo.getterFieldName});");
      } else if (isBuiltin(fieldType)) {
        buffer.writeln(
            "document.put('$keyName', entity.${propInfo.getterFieldName});");
      } else {
        if (fieldType.isDartCoreList) {
          buffer.writeln("document.put('$keyName', EntityConverter."
              "fromList(entity.${propInfo.getterFieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreIterable) {
          buffer.writeln("document.put('$keyName', EntityConverter."
              "fromIterable(entity.${propInfo.getterFieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreSet) {
          buffer.writeln("document.put('$keyName', EntityConverter."
              "fromSet(entity.${propInfo.getterFieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreMap) {
          buffer.writeln("document.put('$keyName', EntityConverter."
              "fromMap(entity.${propInfo.getterFieldName}, nitriteMapper));");
        } else {
          buffer.write("document.put('$keyName', ");
          buffer.write('nitriteMapper.tryConvert<Document, ');
          buffer.write(
              propInfo.fieldType.getDisplayString(withNullability: false));
          buffer.writeln('>(entity.${propInfo.getterFieldName}));');
        }
      }
    }

    buffer.writeln('return document;');

    return buffer.toString();
  }
}
