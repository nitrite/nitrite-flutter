class Pair<A, B> {
  final A first;
  final B second;

  Pair(this.first, this.second);

  @override
  String toString() => '($first, $second)';
}

class Triplet<A, B, C> {
  final A first;
  final B second;
  final C third;

  Triplet(this.first, this.second, this.third);

  @override
  String toString() => '($first, $second, $third)';
}

class Quartet<A, B, C, D> {
  final A first;
  final B second;
  final C third;
  final D fourth;

  Quartet(this.first, this.second, this.third, this.fourth);

  @override
  String toString() => '($first, $second, $third, $fourth)';
}

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

