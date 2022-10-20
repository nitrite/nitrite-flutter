import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// A [NitriteMapper] based on [EntityConverter] implementation.
class SimpleDocumentMapper extends NitriteMapper {
  final Set<String> _valueTypes = {};
  final Map<String, EntityConverter> _converterRegistry = {};

  SimpleDocumentMapper([List<Type> valueTypes = const []]) {
    _registerValueTypes(valueTypes);
  }

  @override
  Target? convert<Target, Source>(Source? source) {
    if (source == null) {
      return null;
    }
    
    if (_isValue(source)) {
      if (source is! Target) {
        throw ObjectMappingException("Cannot convert value type $Source to $Target");
      }

      return source as Target;
    } else {
      if (Target == Document || isSubtype<Target, Document>()) {
        if (source is Document) {
          return source as Target;
        } else {
          return _convertToDocument<Source>(source) as Target;
        }
      } else if (source is Document) {
        return _convertFromDocument<Target, Source>(source);
      }
    }

    throw ObjectMappingException(
      'Cannot convert object of type ${source.runtimeType} '
          'to type ${Target.runtimeType}',
    );
  }

  @override
  Future<void> initialize(NitriteConfig nitriteConfig) async {
  }

  /// Adds a value type to ignore during mapping.
  void addValueType<T>() {
    _valueTypes.add("$T");
    _valueTypes.add("$T?");
  }

  /// Registers an [EntityConverter].
  void registerEntityConverter(EntityConverter<dynamic> entityConverter) {
    entityConverter.notNullOrEmpty("entityConverter cannot be null");
    _converterRegistry["${entityConverter.entityType}"] = entityConverter;
    _converterRegistry["${entityConverter.entityType}?"] = entityConverter;
  }

  _registerValueTypes(List<Type> valueTypes) {
    _valueTypes.addAll(builtInTypes().map((e) => e.toString()));
    _valueTypes.add("$Enum");
    _valueTypes.add("$NitriteId");
    _valueTypes.addAll(valueTypes.map((e) => e.toString()));
  }

  bool _isValue(value) {
    return _valueTypes.any((type) => value.runtimeType.toString() == type);
  }

  /// Converts an object of type [Source] to a document.
  Document _convertToDocument<Source>(Source source) {
    if (_converterRegistry.containsKey("$Source")) {
      var serializer = _converterRegistry["$Source"] as EntityConverter<Source>;
      return serializer.toDocument(source, this);
    }

    throw ObjectMappingException('Can\'t convert object of type '
        '${source.runtimeType} to Document, try registering a '
        'EntityConverter for it.');
  }

  /// Converts a document to a target object of type [Target].
  Target? _convertFromDocument<Target, Source>(Document source) {
    if (_converterRegistry.containsKey("$Target")) {
      var serializer = _converterRegistry["$Target"] as EntityConverter<Target>;
      return serializer.fromDocument(source, this);
    }

    throw ObjectMappingException('Can\'t convert Document to type '
        '${Target.runtimeType}, try registering a EntityConverter for it.');
  }
}