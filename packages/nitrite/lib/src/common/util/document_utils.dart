import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';

FieldValues getDocumentValues(Document document, Fields fields) {
  var fieldValues = FieldValues();
  fieldValues.nitriteId = document.id;
  fieldValues.fields = fields;

  for (var field in fields.fieldNames) {
    var value = document.get(field);
    fieldValues.values.add(Pair(field, value));
  }

  return fieldValues;
}

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
    if (entry.second is Document) {
      newDoc.put(entry.first, _removeValues(entry.second as Document));
    } else {
      newDoc.put(entry.first, null);
    }
  }
  return newDoc;
}
