import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';

/// @nodoc
FieldValues getDocumentValues(Document document, Fields fields) {
  var fieldValues = FieldValues();
  fieldValues.nitriteId = document.id;
  fieldValues.fields = fields;

  for (var field in fields.fieldNames) {
    var value = document.get(field);
    fieldValues.values.add((field, value));
  }

  return fieldValues;
}

/// @nodoc
Document skeletonDocument<T>(NitriteMapper nitriteMapper) {
  var dummy = newInstance<T>(nitriteMapper);
  var document = nitriteMapper.tryConvert<Document, T>(dummy);
  if (document != null) {
    if (document is! Document) {
      throw ObjectMappingException(
          'Cannot convert ${T.runtimeType} to document');
    }

    return _removeValues(document);
  }

  return emptyDocument();
}

Document _removeValues(Document document) {
  if (document.isEmpty) return document;
  var newDoc = emptyDocument();
  for (var entry in document) {
    if (entry.$2 is Document) {
      newDoc.put(entry.$1, _removeValues(entry.$2 as Document));
    } else {
      newDoc.put(entry.$1, null);
    }
  }
  return newDoc;
}
