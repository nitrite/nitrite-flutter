import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_builder/code_builder.dart';
import 'package:nitrite_entity_generator/src/common.dart';
import 'package:nitrite_entity_generator/src/type_checker.dart';

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
    buffer.writeln('var entity = ${_converterInfo.className}();');

    for (var fieldInfo in _converterInfo.fieldInfoList) {
      buffer.write('entity.${fieldInfo.fieldName} = ');

      var propertyName = fieldInfo.fieldName;
      if (fieldInfo.aliasName.isNotEmpty) {
        propertyName = fieldInfo.aliasName;
      }

      var fieldType = fieldInfo.fieldType;
      if (isBuiltin(fieldType)) {
        buffer.writeln("document['$propertyName'];");
      } else {
        if (fieldType.isDartCoreList) {
          buffer.writeln("toList(document['$propertyName'], nitriteMapper);");
        } else if (fieldType.isDartCoreIterable) {
          buffer
              .writeln("toIterable(document['$propertyName'], nitriteMapper);");
        } else if (fieldType.isDartCoreSet) {
          buffer.writeln("toSet(document['$propertyName'], nitriteMapper);");
        } else if (fieldType.isDartCoreMap) {
          buffer.writeln("toMap(document['$propertyName'], nitriteMapper);");
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

    buffer.writeln('return entity;');

    return buffer.toString();
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
          buffer.writeln(
              "document.put('$propertyName', fromList(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreIterable) {
          buffer.writeln(
              "document.put('$propertyName', fromIterable(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreSet) {
          buffer.writeln(
              "document.put('$propertyName', fromSet(entity.${fieldInfo.fieldName}, nitriteMapper));");
        } else if (fieldType.isDartCoreMap) {
          buffer.writeln(
              "document.put('$propertyName', fromMap(entity.${fieldInfo.fieldName}, nitriteMapper));");
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
