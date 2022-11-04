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
      tags.hashCode ^
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
  final String text;
  SuperDuperClass({this.text = ''});

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
  final int id;
  final DateTime? date;

  ParentClass({this.id = 0, this.date});

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

@GenerateConverter()
class ChildClass extends ParentClass {
  final String name;

  ChildClass({this.name = ''});

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
@GenerateConverter()
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

  Employee(
      {this.empId = 0,
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

@GenerateConverter()
class StressRecord {
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

@GenerateConverter()
class WithNitriteId {
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
}

@GenerateConverter()
class WithNullId {
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

@GenerateConverter()
class WithTransientField {
  @IgnoredKey()
  String? name;

  @Id(fieldName: 'number')
  int number;

  WithTransientField({required this.name, required this.number});
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
}