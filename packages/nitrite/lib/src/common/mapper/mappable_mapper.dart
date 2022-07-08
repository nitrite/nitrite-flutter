import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// A [NitriteMapper] based on [Mappable] implementation.
class MappableMapper extends NitriteMapper {
  final Set<Type> _valueTypes = {};
  final Map<Type, MappableFactory> _mappableFactories = {};

  MappableMapper([List<Type> valueTypes = const []]) {
    _valueTypes.add(num);
    _valueTypes.add(String);
    _valueTypes.add(bool);
    _valueTypes.add(Enum);
    _valueTypes.add(Null);
    _valueTypes.add(DateTime);
    _valueTypes.add(NitriteId);

    if (!valueTypes.isNullOrEmpty) {
      _valueTypes.addAll(valueTypes);
    }
  }

  @override
  Target? convert<Target, Source>(Source? source) {
    if (source == null) {
      return null;
    }

    if (isValue(source)) {
      return source as Target;
    } else {
      if (Target == Document) {
        if (source is Document) {
          return source as Target;
        } else {
          return convertToDocument<Source>(source) as Target;
        }
      } else if (source is Document) {
        return convertFromDocument<Target, Source>(source);
      }
    }

    throw ObjectMappingException(
      'Cannot convert object of type ${source.runtimeType} '
      'to type ${Target.runtimeType}',
    );
  }

  @override
  bool isValueType<T>() {
    return _valueTypes.contains(T);
  }

  @override
  bool isValue(value) {
    return _valueTypes.contains(value.runtimeType);
  }

  @override
  T newInstance<T>() {
    var factory = _mappableFactories[T];
    if (factory != null) {
      return factory() as T;
    } else {
      throw ObjectMappingException(
        'Cannot create instance of type ${T.runtimeType} '
        'because no factory was registered.',
      );
    }
  }

  @override
  Future<void> initialize(NitriteConfig nitriteConfig) async {}

  /// Registers a [Mappable] factory method to be used when converting a document
  /// to an object of type [T].
  void registerMappable<T extends Mappable>(MappableFactory<T> factory) {
    _mappableFactories[T] = factory;
  }

  /// Adds a value type to ignore during mapping.
  void addValueType<T>() {
    _valueTypes.add(T);
  }

  /// Converts an object of type [Source] to a document.
  Document convertToDocument<Source>(Source source) {
    if (source is Mappable) {
      return source.write(this);
    }

    throw ObjectMappingException('Object of type ${source.runtimeType} '
        'is not Mappable');
  }

  /// Converts a document to a target object of type [Target].
  Target? convertFromDocument<Target, Source>(Document source) {
    if (isSubtype<Target, Mappable>()) {
      var factory = _mappableFactories[Target];
      if (factory != null) {
        var mappable = factory();
        mappable.read(this, source);
        return mappable as Target;
      } else {
        throw ObjectMappingException(
            'No factory is registered for ${Target.runtimeType}');
      }
    }

    throw ObjectMappingException('${Target.runtimeType} is not a Mappable');
  }
}
