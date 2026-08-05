import 'dart:math';

/// Crockford base32, which omits I, L, O and U so a code read off a console
/// and typed by hand cannot be garbled by the font.
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

const _codeLength = 8;

/// The pairing secret for one bridge session.
///
/// This is the only security control in the system. The bridge runs inside the
/// developer's application, behind an already-open database handle, so neither
/// the Nitrite password nor at-rest encryption applies to a client that pairs
/// — see `docs/THREAT-MODEL.md` §1.
class PairingCode {
  PairingCode(this.value);

  /// 8 characters of Crockford base32: 40 bits.
  ///
  /// Uses [Random.secure]; a predictable code is the same as no code.
  factory PairingCode.generate() {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < _codeLength; i++) {
      buffer.write(_alphabet[random.nextInt(_alphabet.length)]);
    }
    return PairingCode(buffer.toString());
  }

  final String value;

  /// Whether [guess] is this code, compared in constant time.
  ///
  /// A comparison that returns on the first differing character leaks the code
  /// one position at a time, which turns 40 bits into 8 independent searches
  /// of 32. Length is checked first and separately: it is not a secret, and a
  /// wrong-length guess cannot be compared position-wise anyway.
  bool matches(String guess) {
    final normalisedGuess = _normalise(guess);
    final normalisedValue = _normalise(value);
    if (normalisedGuess.length != normalisedValue.length) return false;

    var difference = 0;
    for (var i = 0; i < normalisedValue.length; i++) {
      difference |=
          normalisedValue.codeUnitAt(i) ^ normalisedGuess.codeUnitAt(i);
    }
    return difference == 0;
  }

  /// Crockford's decoding rules: case-insensitive, and the letters that look
  /// like digits decode to those digits.
  static String _normalise(String input) {
    return input
        .toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1');
  }

  @override
  String toString() => value;
}

enum PairingResult {
  paired,

  /// Wrong code, and the gate is still accepting attempts.
  rejected,

  /// The failure ceiling was reached. Nothing reopens the gate except
  /// restarting the host application.
  closed,
}

/// Rate limits pairing attempts for one bridge session.
///
/// Two properties from `docs/THREAT-MODEL.md` F3, both easy to get wrong:
///
/// - **The budget is per session, not per connection.** Counting failures per
///   connection lets an attacker open one connection per guess and never trip
///   the ceiling.
/// - **Backoff delays the response, it does not refuse new connections.** A
///   gate that refuses connections is a free denial of service against the
///   developer, who is the one person who must never be locked out.
class PairingGate {
  PairingGate({
    required PairingCode code,
    Future<void> Function(Duration) delay = _wait,
    this.maxFailures = 10,
  })  : _code = code,
        _delay = delay;

  static Future<void> _wait(Duration d) => Future<void>.delayed(d);

  final PairingCode _code;
  final Future<void> Function(Duration) _delay;

  /// Total failures allowed before pairing closes for the session.
  final int maxFailures;

  int _failures = 0;

  int get failureCount => _failures;

  bool get isClosed => _failures >= maxFailures;

  Future<PairingResult> attempt(String guess) async {
    if (isClosed) return PairingResult.closed;

    if (_code.matches(guess)) {
      // Deliberately does not reset [_failures]: otherwise a guessing run can
      // be laundered through any legitimate pairing for a fresh budget.
      return PairingResult.paired;
    }

    await _delay(_backoffFor(_failures));
    _failures++;

    return isClosed ? PairingResult.closed : PairingResult.rejected;
  }

  /// First failure answers immediately, then 1s doubling to a 60s cap. A
  /// developer who fat-fingers the code once should not wait for it.
  Duration _backoffFor(int priorFailures) {
    if (priorFailures == 0) return Duration.zero;
    final seconds = 1 << (priorFailures - 1);
    return Duration(seconds: seconds > 60 ? 60 : seconds);
  }
}
