import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/number_utils.dart';

part 'test_objects.no2.dart';

@GenerateConverter(className: 'MyBookConverter')
@Entity(name: 'books', indices: [
  Index(fields: ['tags'], type: IndexType.nonUnique),
  Index(fields: ['description'], type: IndexType.fullText),
  Index(fields: ['price', 'publisher']),
])
class Book with _$BookEntityMixin {
  @Id(fieldName: 'book_id', embeddedFields: ['isbn', 'book_name'])
  @DocumentKey(alias: 'book_id')
  BookId? bookId;

  String? publisher;

  double? price;

  List<String> tags = [];

  String? description;

  Book(
      [this.bookId,
      this.publisher,
      this.price,
      this.tags = const [],
      this.description]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          publisher == other.publisher &&
          price == other.price &&
          ListEquality().equals(tags, other.tags) &&
          description == other.description;

  @override
  int get hashCode =>
      bookId.hashCode ^
      publisher.hashCode ^
      price.hashCode ^
      ListEquality().hash(tags) ^
      description.hashCode;
}

@GenerateConverter()
class BookId {
  String? isbn;

  @DocumentKey(alias: "book_name")
  String? name;

  @IgnoredKey()
  String? author;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookId &&
          runtimeType == other.runtimeType &&
          isbn == other.isbn &&
          name == other.name &&
          author == other.author;

  @override
  int get hashCode => isbn.hashCode ^ name.hashCode ^ author.hashCode;
}

@Index(fields: ['text'], type: IndexType.fullText)
abstract class SuperDuperClass {
  String? text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperDuperClass &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;
}

@Index(fields: ['date'])
abstract class ParentClass extends SuperDuperClass {
  @Id(fieldName: 'id')
  int? id;
  DateTime? date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ParentClass &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date;

  @override
  int get hashCode => super.hashCode ^ id.hashCode ^ date.hashCode;
}

@Entity()
@GenerateConverter()
class ChildClass extends ParentClass with _$ChildClassEntityMixin {
  String? name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ChildClass &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => super.hashCode ^ name.hashCode;
}

@Entity()
@GenerateConverter()
class ClassA with _$ClassAEntityMixin {
  ClassB? b;
  String? uid;
  String? string;
  List<int>? blob;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassA &&
          runtimeType == other.runtimeType &&
          b == other.b &&
          uid == other.uid &&
          string == other.string &&
          ListEquality().equals(blob, other.blob);

  @override
  int get hashCode =>
      b.hashCode ^ uid.hashCode ^ string.hashCode ^ blob.hashCode;
}

@GenerateConverter()
class ClassB implements Comparable<ClassB> {
  int? number;
  String? text;

  @override
  int compareTo(ClassB other) {
    return compareNum(number!, other.number!);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassB &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          text == other.text;

  @override
  int get hashCode => number.hashCode ^ text.hashCode;
}

@Entity()
@GenerateConverter()
class ClassC with _$ClassCEntityMixin {
  int? id;
  double? digit;
  ClassA? parent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassC &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          digit == other.digit &&
          parent == other.parent;

  @override
  int get hashCode => id.hashCode ^ digit.hashCode ^ parent.hashCode;
}

@Entity(indices: [
  Index(fields: ['companyName'])
])
class Company with _$CompanyEntityMixin {
  @Id(fieldName: 'company_id')
  @DocumentKey(alias: 'company_id')
  final int companyId;
  final String companyName;
  final DateTime? dateCreated;
  final List<String> departments;
  final Map<String, List<Employee>> employeeRecord;

  Company(
      {this.companyId = 0,
      this.companyName = '',
      this.dateCreated,
      this.departments = const [],
      this.employeeRecord = const {}});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Company &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          companyName == other.companyName &&
          dateCreated == other.dateCreated &&
          ListEquality().equals(departments, other.departments) &&
          MapEquality<String, List<Employee>>()
              .equals(employeeRecord, other.employeeRecord);

  @override
  int get hashCode =>
      companyId.hashCode ^
      companyName.hashCode ^
      dateCreated.hashCode ^
      departments.hashCode ^
      employeeRecord.hashCode;
}

class CompanyConverter extends EntityConverter<Company> {
  @override
  Company fromDocument(
    Document document,
    NitriteMapper nitriteMapper,
  ) {
    var map = <String, List<Employee>>{};
    var employeeRecords = document['employeeRecord'] == null
        ? {}
        : document['employeeRecord'] as Map;

    for (var entry in employeeRecords.entries) {
      var key = nitriteMapper.convert<String, dynamic>(entry.key);
      var value = EntityConverter.toList<Employee>(entry.value, nitriteMapper);
      map[key] = value;
    }

    var entity = Company(
      companyId: document['company_id'] ?? 0,
      companyName: document['companyName'] ?? "",
      dateCreated: document['dateCreated'],
      departments:
          EntityConverter.toList(document['departments'], nitriteMapper),
      employeeRecord: map,
    );

    return entity;
  }

  @override
  Document toDocument(
    Company entity,
    NitriteMapper nitriteMapper,
  ) {
    var document = emptyDocument();
    document.put('company_id', entity.companyId);
    document.put('companyName', entity.companyName);
    document.put('dateCreated', entity.dateCreated);
    document.put('departments',
        EntityConverter.fromList(entity.departments, nitriteMapper));
    document.put('employeeRecord',
        EntityConverter.fromMap(entity.employeeRecord, nitriteMapper));
    return document;
  }
}

@Entity(indices: [
  Index(fields: ["joinDate"], type: IndexType.nonUnique),
  Index(fields: ["address"], type: IndexType.fullText),
  Index(fields: ["employeeNote.text"], type: IndexType.fullText),
])
@GenerateConverter()
class Employee with _$EmployeeEntityMixin {
  @Id(fieldName: 'empId')
  int? empId;
  DateTime? joinDate;
  String address;
  String emailAddress;
  List<int> blob;
  @IgnoredKey()
  Company? company;
  Note? employeeNote;

  static Employee clone(Employee employee) {
    return Employee(
        address: employee.address,
        blob: employee.blob,
        company: employee.company,
        emailAddress: employee.emailAddress,
        empId: employee.empId,
        joinDate: employee.joinDate,
        employeeNote: employee.employeeNote);
  }

  Employee(
      {this.empId,
      this.joinDate,
      this.address = '',
      this.emailAddress = '',
      this.blob = const [],
      this.company,
      this.employeeNote});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          empId == other.empId &&
          joinDate == other.joinDate &&
          address == other.address &&
          emailAddress == other.emailAddress &&
          ListEquality().equals(blob, other.blob) &&
          company == other.company &&
          employeeNote == other.employeeNote;

  @override
  int get hashCode =>
      empId.hashCode ^
      joinDate.hashCode ^
      address.hashCode ^
      emailAddress.hashCode ^
      blob.hashCode ^
      company.hashCode ^
      employeeNote.hashCode;

  @override
  String toString() {
    return "{empId: $empId}";
  }
}

@GenerateConverter()
class SubEmployee {
  int? empId;
  DateTime? joinDate;
  String? address;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubEmployee &&
          runtimeType == other.runtimeType &&
          empId == other.empId &&
          joinDate == other.joinDate &&
          address == other.address;

  @override
  int get hashCode => empId.hashCode ^ joinDate.hashCode ^ address.hashCode;
}

@GenerateConverter()
class Note {
  final int noteId;
  final String text;

  Note({this.noteId = 0, this.text = ''});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          noteId == other.noteId &&
          text == other.text;

  @override
  int get hashCode => noteId.hashCode ^ text.hashCode;

  @override
  String toString() {
    return 'Note{noteId: $noteId, text: $text}';
  }
}

@GenerateConverter()
class ElemMatch {
  int? id;
  List<String>? strArray;
  List<ProductScore>? productScores;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElemMatch &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ListEquality().equals(strArray, other.strArray) &&
          ListEquality().equals(productScores, other.productScores);

  @override
  int get hashCode => id.hashCode ^ strArray.hashCode ^ productScores.hashCode;
}

@GenerateConverter()
class ProductScore {
  String? product;
  int? score;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductScore &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          score == other.score;

  @override
  int get hashCode => product.hashCode ^ score.hashCode;
}

@GenerateConverter()
class EmptyClass {}

@GenerateConverter()
class EncryptedPerson {
  String? name;
  String? creditCardNumber;
  String? cvv;
  DateTime? expiryDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncryptedPerson &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          creditCardNumber == other.creditCardNumber &&
          cvv == other.cvv &&
          expiryDate == other.expiryDate;

  @override
  int get hashCode =>
      name.hashCode ^
      creditCardNumber.hashCode ^
      cvv.hashCode ^
      expiryDate.hashCode;
}

@Entity(name: 'MyPerson', indices: [
  Index(fields: ['name'], type: IndexType.fullText),
  Index(fields: ['status'], type: IndexType.nonUnique)
])
@GenerateConverter()
class PersonEntity with _$PersonEntityEntityMixin {
  @Id(fieldName: 'uuid')
  String? uuid;
  String? name;
  String? status;
  PersonEntity? friend;
  DateTime? dateCreated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonEntity &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid &&
          name == other.name &&
          status == other.status &&
          friend == other.friend &&
          dateCreated == other.dateCreated;

  @override
  int get hashCode =>
      uuid.hashCode ^
      name.hashCode ^
      status.hashCode ^
      friend.hashCode ^
      dateCreated.hashCode;
}

@Entity(indices: [
  Index(fields: ['firstName']),
  Index(fields: ['lastName'], type: IndexType.fullText),
  Index(fields: ['age'], type: IndexType.nonUnique)
])
@GenerateConverter()
class RepeatableIndexTest with _$RepeatableIndexTestEntityMixin {
  String? firstName;
  int? age;
  String? lastName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatableIndexTest &&
          runtimeType == other.runtimeType &&
          firstName == other.firstName &&
          age == other.age &&
          lastName == other.lastName;

  @override
  int get hashCode => firstName.hashCode ^ age.hashCode ^ lastName.hashCode;
}

@Entity()
@GenerateConverter()
class StressRecord with _$StressRecordEntityMixin {
  String? firstName;
  String? lastName;
  bool? processed;
  bool? failed;
  String? notes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StressRecord &&
          runtimeType == other.runtimeType &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          processed == other.processed &&
          failed == other.failed &&
          notes == other.notes;

  @override
  int get hashCode =>
      firstName.hashCode ^
      lastName.hashCode ^
      processed.hashCode ^
      failed.hashCode ^
      notes.hashCode;
}

@GenerateConverter()
class WithCircularReference {
  String? name;
  WithCircularReference? parent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithCircularReference &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          parent == other.parent;

  @override
  int get hashCode => name.hashCode ^ parent.hashCode;
}

@GenerateConverter()
class WithTypeField {
  @Id(fieldName: 'name')
  String? name;
  Type? clazz;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithTypeField &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          clazz == other.clazz;

  @override
  int get hashCode => name.hashCode ^ clazz.hashCode;
}

@GenerateConverter()
class WithDateId {
  @Id(fieldName: 'id')
  DateTime id;
  String name;

  WithDateId({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithDateId &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class WithDateIdDecorator extends EntityDecorator<WithDateId> {
  @override
  EntityId? get idField => EntityId('id');

  @override
  List<EntityIndex> get indexFields => [];
}

@GenerateConverter()
class WithEmptyStringId {
  @Id(fieldName: 'name')
  final String name;

  WithEmptyStringId({required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithEmptyStringId &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class WithEmptyStringIdEntityDecorator
    extends EntityDecorator<WithEmptyStringId> {
  @override
  EntityId? get idField => EntityId('name');

  @override
  List<EntityIndex> get indexFields => [];
}

@Entity()
@GenerateConverter()
class WithNitriteId with _$WithNitriteIdEntityMixin {
  @Id(fieldName: 'idField')
  NitriteId? idField;
  String? name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithNitriteId &&
          runtimeType == other.runtimeType &&
          idField == other.idField &&
          name == other.name;

  @override
  int get hashCode => idField.hashCode ^ name.hashCode;

  @override
  String toString() {
    return "{idField: $idField, name: $name}";
  }
}

@Entity()
@GenerateConverter()
class WithNullId with _$WithNullIdEntityMixin {
  @Id(fieldName: 'name')
  String? name;
  int? number;
}

@GenerateConverter()
class WithObjectId {
  @Id(fieldName: 'withOutId', embeddedFields: ['name', 'number'])
  WithOutId? withOutId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithObjectId &&
          runtimeType == other.runtimeType &&
          withOutId == other.withOutId;

  @override
  int get hashCode => withOutId.hashCode;
}

@GenerateConverter()
class WithOutId implements Comparable<WithOutId> {
  final String name;
  final int number;

  WithOutId({required this.name, required this.number});

  @override
  int compareTo(WithOutId other) {
    return compareNum(number, other.number);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithOutId &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          number == other.number;

  @override
  int get hashCode => name.hashCode ^ number.hashCode;
}

class WithOutIdEntityDecorator extends EntityDecorator<WithOutId> {
  @override
  EntityId? get idField => null;

  @override
  List<EntityIndex> get indexFields => [];
}

@GenerateConverter()
class WithTransientField {
  @IgnoredKey()
  String? name;

  @Id(fieldName: 'number')
  int number;

  WithTransientField({required this.name, required this.number});
}

class WithTransientFieldDecorator extends EntityDecorator<WithTransientField> {
  @override
  EntityId? get idField => EntityId('number');

  @override
  List<EntityIndex> get indexFields => [];
}

@Entity(indices: [
  Index(fields: ['text'], type: IndexType.fullText)
])
@GenerateConverter()
class TextData with _$TextDataEntityMixin {
  int? id;
  String? text;
}

@GenerateConverter()
class TxData {
  @Id(fieldName: 'id')
  int? id;
  String? name;
}

@Entity(indices: [
  Index(fields: ["joinDate"], type: IndexType.nonUnique),
  Index(fields: ["address"], type: IndexType.fullText),
  Index(fields: ["employeeNote:text"], type: IndexType.fullText),
])
@GenerateConverter()
class EmployeeForCustomSeparator with _$EmployeeForCustomSeparatorEntityMixin {
  @Id(fieldName: 'empId')
  int? empId;
  DateTime? joinDate;
  String? address;
  String? emailAddress;
  List<int>? blob;
  @IgnoredKey()
  Company? company;
  Note? employeeNote;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          empId == other.empId &&
          joinDate == other.joinDate &&
          address == other.address &&
          emailAddress == other.emailAddress &&
          ListEquality().equals(blob, other.blob) &&
          company == other.company &&
          employeeNote == other.employeeNote;

  @override
  int get hashCode =>
      empId.hashCode ^
      joinDate.hashCode ^
      address.hashCode ^
      emailAddress.hashCode ^
      blob.hashCode ^
      company.hashCode ^
      employeeNote.hashCode;

  @override
  String toString() {
    return 'EmployeeForCustomSeparator{'
        'empId: $empId, '
        'joinDate: $joinDate, '
        'address: $address, '
        'emailAddress: $emailAddress, '
        'blob: $blob, '
        'company: $company, '
        'employeeNote: $employeeNote}';
  }
}
