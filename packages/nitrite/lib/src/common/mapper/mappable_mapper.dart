import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// A [NitriteMapper] based on [Mappable] implementation.
class MappableMapper extends NitriteMapper {
  final Map<Type, MappableFactory> _mappableFactories = {};
  final Set<Type> _valueTypes = {};

  /// Creates a new instance of [MappableMapper].
  MappableMapper([List<Type> valueTypes = const []]) {
    _valueTypes.add(num);
    _valueTypes.add(int);
    _valueTypes.add(double);
    _valueTypes.add(String);
    _valueTypes.add(bool);
    _valueTypes.add(Null);
    _valueTypes.add(DateTime);
    _valueTypes.add(Duration);
    _valueTypes.add(NitriteId);

    if (!valueTypes.isNullOrEmpty) {
      _valueTypes.addAll(valueTypes);
    }
  }

  /// Registers a [Mappable] factory method to be used when converting a document
  /// to an object of type [T].
  void registerMappable<T extends Mappable>(MappableFactory<T> factory) {
    _mappableFactories[T] = factory;
  }

  @override
  Target? convert<Target, Source>(Source? source) {
    if (source == null) {
      return null;
    }

    if (isValue(source) && source is Target) {
      return source as Target;
    } else {
      if (Target == Document) {
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
  bool isValueType<T>() {
    return _valueTypes.contains(T);
  }

  @override
  bool isValue(value) {
    return _valueTypes.any((type) => value.runtimeType == type);
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

  /// Adds a value type to ignore during mapping.
  void addValueType<T>() {
    _valueTypes.add(T);
  }

  /// Converts an object of type [Source] to a document.
  Document _convertToDocument<Source>(Source source) {
    if (source is Mappable) {
      return source.write(this);
    }

    throw ObjectMappingException('Object of type ${source.runtimeType} '
        'is not Mappable');
  }

  /// Converts a document to a target object of type [Target].
  Target? _convertFromDocument<Target, Source>(Document source) {
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