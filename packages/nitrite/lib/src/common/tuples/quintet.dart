class Quintet<A, B, C, D, E> {
  final A first;
  final B second;
  final C third;
  final D fourth;
  final E fifth;

  Quintet(this.first, this.second, this.third, this.fourth, this.fifth);

  @override
  String toString() => '($first, $second, $third, $fourth, $fifth)';
}
