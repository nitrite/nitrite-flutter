class Pair<A, B> {
  final A first;
  final B second;

  Pair(this.first, this.second);

  @override
  String toString() => '($first, $second)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pair &&
          runtimeType == other.runtimeType &&
          first == other.first &&
          second == other.second;

  @override
  int get hashCode => first.hashCode ^ second.hashCode;
}

class Triplet<A, B, C> {
  final A first;
  final B second;
  final C third;

  Triplet(this.first, this.second, this.third);

  @override
  String toString() => '($first, $second, $third)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Triplet &&
          runtimeType == other.runtimeType &&
          first == other.first &&
          second == other.second &&
          third == other.third;

  @override
  int get hashCode => first.hashCode ^ second.hashCode ^ third.hashCode;
}

class Quartet<A, B, C, D> {
  final A first;
  final B second;
  final C third;
  final D fourth;

  Quartet(this.first, this.second, this.third, this.fourth);

  @override
  String toString() => '($first, $second, $third, $fourth)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quartet &&
          runtimeType == other.runtimeType &&
          first == other.first &&
          second == other.second &&
          third == other.third &&
          fourth == other.fourth;

  @override
  int get hashCode =>
      first.hashCode ^ second.hashCode ^ third.hashCode ^ fourth.hashCode;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quintet &&
          runtimeType == other.runtimeType &&
          first == other.first &&
          second == other.second &&
          third == other.third &&
          fourth == other.fourth &&
          fifth == other.fifth;

  @override
  int get hashCode =>
      first.hashCode ^
      second.hashCode ^
      third.hashCode ^
      fourth.hashCode ^
      fifth.hashCode;
}
