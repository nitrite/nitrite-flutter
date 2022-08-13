import 'package:nitrite/nitrite.dart';

Future<Nitrite> createDb([String? user, String? password]) =>
    Nitrite.builder().fieldSeparator(".").openOrCreate(user, password);
