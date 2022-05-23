class Quartet<A, B, C, D> {
  final A first;
  final B second;
  final C third;
  final D fourth;

  Quartet(this.first, this.second, this.third, this.fourth);

  @override
  String toString() => '($first, $second, $third, $fourth)';
}
