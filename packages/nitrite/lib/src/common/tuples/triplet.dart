class Triplet<A, B, C> {
  final A first;
  final B second;
  final C third;

  Triplet(this.first, this.second, this.third);

  @override
  String toString() => '($first, $second, $third)';
}
