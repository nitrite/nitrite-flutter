import 'package:nitrite_bridge/src/pairing.dart';
import 'package:test/test.dart';

void main() {
  group('pairing code', () {
    test('is 8 characters of Crockford base32', () {
      // THREAT-MODEL F3: 40 bits. Six digits (~20 bits) was brute-forceable in
      // about 70 days against a bridge left running, which developers do.
      for (var i = 0; i < 200; i++) {
        final code = PairingCode.generate();
        expect(
            code.value, matches(RegExp(r'^[0-9ABCDEFGHJKMNPQRSTVWXYZ]{8}$')));
      }
    });

    test('excludes the ambiguous letters I, L, O and U', () {
      // Crockford base32: the code is read off a console and typed by hand.
      final alphabet = <String>{};
      for (var i = 0; i < 500; i++) {
        alphabet.addAll(PairingCode.generate().value.split(''));
      }
      expect(alphabet.intersection({'I', 'L', 'O', 'U'}), isEmpty);
    });

    test('does not repeat across sessions', () {
      final codes = List.generate(500, (_) => PairingCode.generate().value);
      expect(codes.toSet().length, codes.length);
    });

    test('accepts the correct code', () {
      final code = PairingCode.generate();
      expect(code.matches(code.value), isTrue);
    });

    test('rejects a wrong code, including one differing in the last character',
        () {
      final code = PairingCode('ABCDEFGH');
      expect(code.matches('ABCDEFGJ'), isFalse);
      expect(code.matches('ZBCDEFGH'), isFalse);
      expect(code.matches(''), isFalse);
      expect(code.matches('ABCDEFGHI'), isFalse);
    });

    test('is case-insensitive and tolerates Crockford digit confusions', () {
      // A developer reading a code off a console types what they see; 'l' for
      // '1' and 'O' for '0' are the classic misreads Crockford base32 defines
      // away. Refusing them would be blaming the user for the font.
      final code = PairingCode('ABCD0123');
      expect(code.matches('abcd0123'), isTrue);
      expect(code.matches('ABCDO123'), isTrue, reason: 'O reads as 0');
      expect(code.matches('ABCD0I23'), isTrue, reason: 'I reads as 1');
      expect(code.matches('ABCD0L23'), isTrue, reason: 'L reads as 1');
    });

    test('comparison time does not depend on the matching prefix length', () {
      // THREAT-MODEL acceptance criterion 4. A comparison that returns early
      // on the first wrong character leaks the code one position at a time.
      final code = PairingCode('ABCDEFGH');
      const samples = 10000;

      int timeFor(String guess) {
        final sw = Stopwatch()..start();
        for (var i = 0; i < samples; i++) {
          code.matches(guess);
        }
        return sw.elapsedMicroseconds;
      }

      // Warm up, so JIT compilation does not land inside a measured run.
      timeFor('ZZZZZZZZ');

      final noMatch = timeFor('ZZZZZZZZ');
      final almostAll = timeFor('ABCDEFGZ');

      final ratio = almostAll / noMatch;
      expect(
        ratio,
        inInclusiveRange(0.5, 2.0),
        reason: 'timing varied with prefix length: '
            'none=${noMatch}us almost=${almostAll}us ratio=$ratio',
      );
    });
  });

  group('pairing gate', () {
    late PairingCode code;
    late List<Duration> delays;
    late PairingGate gate;

    setUp(() {
      code = PairingCode('ABCDEFGH');
      delays = [];
      gate = PairingGate(code: code, delay: (d) async => delays.add(d));
    });

    test('a correct code pairs', () async {
      expect(await gate.attempt('ABCDEFGH'), PairingResult.paired);
    });

    test('a wrong code fails without delaying the first response', () async {
      expect(await gate.attempt('WRONG123'), PairingResult.rejected);
      expect(delays, [Duration.zero]);
    });

    test('backoff doubles from 1s and caps at 60s', () async {
      // THREAT-MODEL F3. The delay is on the *response*; new connections are
      // never refused, so this cannot be turned into a lockout on the developer.
      for (var i = 0; i < 10; i++) {
        await gate.attempt('WRONG123');
      }

      expect(delays, [
        Duration.zero,
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        const Duration(seconds: 4),
        const Duration(seconds: 8),
        const Duration(seconds: 16),
        const Duration(seconds: 32),
        const Duration(seconds: 60),
        const Duration(seconds: 60),
        const Duration(seconds: 60),
      ]);
    });

    test('10 failures close pairing for the lifetime of the gate', () async {
      for (var i = 0; i < 9; i++) {
        expect(await gate.attempt('WRONG123'), PairingResult.rejected);
      }

      // The 10th failure is the one that closes the gate, and says so rather
      // than reporting a plain rejection — a developer who has locked
      // themselves out should learn they must restart now, not one attempt
      // later.
      expect(await gate.attempt('WRONG123'), PairingResult.closed);

      // Acceptance criterion 3: closed until the application restarts — so
      // even the correct code must not reopen it.
      expect(await gate.attempt('ABCDEFGH'), PairingResult.closed);
      expect(gate.isClosed, isTrue);
    });

    test('the budget is per gate, not per attempt sequence', () async {
      // F3: counting failures per connection lets an attacker open one
      // connection per guess and never trip the ceiling. The gate is owned by
      // the server session, so attempts from anywhere share one budget.
      for (var i = 0; i < 9; i++) {
        await gate.attempt('WRONG123');
      }
      expect(gate.failureCount, 9);
      expect(await gate.attempt('WRONG123'), PairingResult.closed);
      expect(await gate.attempt('WRONG123'), PairingResult.closed);
    });

    test('a successful pairing does not reset the failure budget', () async {
      for (var i = 0; i < 5; i++) {
        await gate.attempt('WRONG123');
      }
      expect(await gate.attempt('ABCDEFGH'), PairingResult.paired);

      // Otherwise an attacker who learns the code once buys a fresh budget,
      // and a guessing run can be laundered through any legitimate pairing.
      expect(gate.failureCount, 5);
    });
  });
}
