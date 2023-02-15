import 'package:nitrite/nitrite.dart';

part 'test_objects_decorators.no2.dart';

@GenerateConverter()
class Manufacturer {
  String? name;
  String? address;
  int? uniqueId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Manufacturer &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address &&
          uniqueId == other.uniqueId;

  @override
  int get hashCode => name.hashCode ^ address.hashCode ^ uniqueId.hashCode;
}

class ManufacturerDecorator extends EntityDecorator<Manufacturer> {
  @override
  EntityId? get idField => null;

  @override
  List<EntityIndex> get indexFields => [];
}

@GenerateConverter()
class MiniProduct {
  String? uniqueId;
  String? manufacturerName;
  double? price;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MiniProduct &&
          runtimeType == other.runtimeType &&
          uniqueId == other.uniqueId &&
          manufacturerName == other.manufacturerName &&
          price == other.price;

  @override
  int get hashCode =>
      uniqueId.hashCode ^ manufacturerName.hashCode ^ price.hashCode;
}

@GenerateConverter()
class Product {
  final ProductId? productId;
  final Manufacturer? manufacturer;
  final String productName;
  final double price;

  Product(
      {required this.productId,
      required this.manufacturer,
      required this.productName,
      required this.price});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          manufacturer == other.manufacturer &&
          productName == other.productName &&
          price == other.price;

  @override
  int get hashCode =>
      productId.hashCode ^
      manufacturer.hashCode ^
      productName.hashCode ^
      price.hashCode;
}

@GenerateConverter()
class ProductId {
  final String uniqueId;
  final String productCode;

  ProductId({required this.uniqueId, required this.productCode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductId &&
          runtimeType == other.runtimeType &&
          uniqueId == other.uniqueId &&
          productCode == other.productCode;

  @override
  int get hashCode => uniqueId.hashCode ^ productCode.hashCode;
}

class ProductDecorator extends EntityDecorator<Product> {
  @override
  EntityId? get idField =>
      EntityId('productId', false, ['uniqueId', 'productCode']);

  @override
  List<EntityIndex> get indexFields => [
        EntityIndex(['manufacturer.name'], IndexType.nonUnique),
        EntityIndex(['productName', 'manufacturer.uniqueId']),
      ];

  @override
  String get entityName => 'product';
}
