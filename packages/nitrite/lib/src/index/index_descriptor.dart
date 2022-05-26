class IndexDescriptor implements Comparable<IndexDescriptor> {
  final String indexType;
  final Fields indexFields;
  final String collectionName;

  IndexDescriptor(this.indexType, this.indexFields, this.collectionName);
}
