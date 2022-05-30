import 'package:nitrite/nitrite.dart';

class IndexDescriptor implements Comparable<IndexDescriptor> {
  final String indexType;
  final Fields indexFields;
  final String collectionName;

  IndexDescriptor(this.indexType, this.indexFields, this.collectionName);

  @override
  int compareTo(IndexDescriptor other) {
    // TODO: implement compareTo
    throw UnimplementedError();
  }
}
