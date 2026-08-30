# nitrite_bridge

Inspect a running application's Nitrite database from a desktop client, over a
paired, loopback-by-default connection.

This package is the **Nitrite adapter** for [`dbinspect_bridge`][core]. The
bridge core — the wire protocol, pairing, the WebSocket transport and the
release-build guard — is engine-neutral and lives there; this package adds the
piece that knows about Nitrite, so that inspecting a Nitrite database pulls in
Nitrite and nothing else.

```dart
import 'package:nitrite_bridge/nitrite_bridge.dart';

final bridge = await startBridge(
  appName: 'my_app',
  adapters: [
    NitriteAdapter(db, id: 'main', displayName: 'app data'),
  ],
);
// The pairing code is printed through `package:logging`. An application that
// does not listen to that logger will never see it:
//   Logger.root.level = Level.INFO;
//   Logger.root.onRecord.listen((r) => print(r.message));
```

In a release build `startBridge` returns `null` and the server is not in the
binary at all.

## What it exposes

**Collections are discovered. Repositories are handed in.**

```dart
NitriteAdapter(db, id: 'main', displayName: 'app data', repositories: [orders]);
```

`Nitrite` opens an `ObjectRepository` by Dart type, and a store name arriving
over a socket is not a type — the entity-name-to-type mapping lives in your
generated code, not in the store. So you pass the repositories you want
inspected. A repository you do not pass is not listed, rather than listed and
unopenable.

Schemas are **inferred** from a sample of documents (50 by default) and always
reported as inferred. A document store has no fixed schema, and a client must
never present a sample as a guarantee.

## Everything dangerous is off

| Option | Default | What it turns on |
|---|---|---|
| `allowRegex` | `false` | the `regex` filter operator |
| `allowWrite` | `false` | row editing — `insertRow`, `updateRow`, `deleteRow` |
| `allowSnapshot` | `false` | whole-store snapshot |

An option that is off is **absent from `capabilities`**, not merely refused when
called, so a client greys the control out rather than offering it and failing.

**A row is addressed by `_id`.** With `allowWrite: true`, `updateRow` and
`deleteRow` take the value the grid showed in that column — a decimal string
here, and the number and the bracketed `[1755…]` form other runtimes render are
accepted too, so an id pasted from another grid works. `_id` inside an update's
`values` is refused: Nitrite merges an update document, so it would rewrite the
identity of the row it just matched — and here it would report `changes: 0`
while doing nothing at all. An update is partial, and `changes: 0` means the row
was not there, which is an answer rather than an error.

`regex` is off by default for a specific reason: Dart's `RegExp` backtracks, a
pattern like `(a+)+$` can pin a core inside your running application, and a Dart
match cannot be interrupted once it has started. With it on, patterns are capped
at 256 characters and nested quantifiers are refused — best-effort, which is why
the default is the mitigation that matters.

## Filter operators

Reported in `capabilities.filterOps`, and this implementation's set is:

`eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `in`, `notIn`, `exists`, `text`, plus
`and`, `or`, `not` — and `regex` when you allow it.

**`exists` needs nitrite 3.0.0**, which is the floor this package sets. It tests
presence only: a field explicitly set to null is present and matches, and "does
not have the field" is `not` around it, never `exists` with `value: false`. Do
not assume parity with the Java or Rust adapters; each reports what it actually
implements.

## Watch

`NitriteAdapter` reports `watch: true` with `watchScope: "engine"` — Nitrite's
subscription is collection-level and sees every write in the process, not only
the ones made through the bridge. Subscriptions belong to the client connection
and are released when it closes, however it closes.

## Security

`docs/THREAT-MODEL.md` in the [dbinspect][repo] repository is binding on this
package. The short version: the bridge sits behind an already-open database
handle, so the pairing secret is the only control between a network peer and the
whole database. It binds loopback by default, `adb forward` is the intended
workflow, leaving loopback forces TLS, and ten wrong pairing codes close pairing
until the application restarts.

Apache-2.0.

[core]: https://pub.dev/packages/dbinspect_bridge
[repo]: https://github.com/nitrite/dbinspect
