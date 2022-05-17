class NitriteException implements Exception {
  final String? message;

  NitriteException([this.message]);

  @override
  String toString() => message ?? "NitriteException";
}
