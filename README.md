# SecureNotesRASP

Encrypted local storage + runtime tamper detection for iOS, built to demonstrate
production-grade secure data handling for a fintech/banking codebase.

## Part 1 — GRDB + SQLCipher

- GRDB and SQLCipher wired together via SPM by vendoring and patching GRDB.swift's
  `Package.swift` (GRDB has no stock SPM path to SQLCipher — the official fork
  instructions are followed in [`Vendor/GRDB.swift/Package.swift`](Vendor/GRDB.swift/Package.swift)).
- The 256-bit encryption passphrase is generated and read back through the Keychain
  ([`PassphraseStore.swift`](SecureNotesRASP/Sources/PassphraseStore.swift)),
  `.accessibleWhenUnlockedThisDeviceOnly`, no `synchronizable`.
- `DatabaseQueue` is opened with `usePassphrase(...)` on first launch
  ([`DatabaseManager.swift`](SecureNotesRASP/Sources/DatabaseManager.swift)); a
  `DatabaseMigrator` creates the `secureNote` table.
- `SecureNote` is a plain `Codable` + `FetchableRecord` + `PersistableRecord` GRDB
  record ([`SecureNote.swift`](SecureNotesRASP/Sources/SecureNote.swift)).
- **Proof of encryption**: the app UI ([`ContentView.swift`](SecureNotesRASP/Sources/ContentView.swift))
  seeds an identical row into two on-disk databases — one opened with SQLCipher,
  one without — and renders a live hex/ASCII dump of both side by side. The
  plaintext file's `SQLite format 3` header and row text are readable; the
  SQLCipher file is indistinguishable from random bytes. [`Artifacts/`](Artifacts/)
  holds a captured before/after DB pair as a static reference.

## Frameworks used

**SQLCipher** ([`sqlcipher/SQLCipher.swift`](https://github.com/sqlcipher/SQLCipher.swift))
— a drop-in replacement for SQLite that transparently encrypts the entire
database file (AES-256, page-level) using a passphrase supplied at connection
time. It's the actual security boundary in this project: without it, `app.db`
sitting in `Application Support/` is a plain file anyone with filesystem access
(a jailbroken device, an unencrypted backup, a stolen disk image) can open and
read directly — no exploit required. Pulled in because Apple's stock
`libsqlite3` has no encryption support at all.

**GRDB** ([`groue/GRDB.swift`](https://github.com/groue/GRDB.swift)) — a Swift
toolkit on top of SQLite/SQLCipher. It doesn't provide any security itself;
it exists to make talking to the (encrypted) database ergonomic and safe from
a different angle: `FetchableRecord`/`PersistableRecord` give typed,
`Codable`-based reads and writes instead of hand-rolled SQL strings and manual
column parsing (which is exactly the kind of code that grows SQL-injection
and off-by-one bugs), `DatabaseQueue` serializes access so concurrent reads/
writes from different threads can't corrupt data, and `DatabaseMigrator` gives
versioned schema changes so the on-disk schema can evolve without ever losing
existing rows. Chosen over Core Data because it's a much thinner layer over
real SQL (nothing to fight when the requirement is "encrypt the whole file with
SQLCipher") and it's SPM-native, unlike Core Data's `.xcdatamodeld` tooling.

**Tuist** ([`tuist/tuist`](https://github.com/tuist/tuist)) — generates the
`.xcodeproj`/`.xcworkspace` from `Project.swift` and `Tuist/Package.swift`
instead of them being hand-maintained or clicked together in Xcode's GUI.
Used here specifically because wiring GRDB to SQLCipher requires a *local,
patched* SPM package (see below) plus a custom app target — both are just
version-controlled Swift code with Tuist, regenerated with `tuist generate`
rather than living as binary `.pbxproj` diffs.

## Project layout

- `Project.swift`, `Tuist.swift`, `Tuist/Package.swift` — Tuist-generated Xcode
  project config (SPM dependency graph lives in `Tuist/Package.swift`).
- `SecureNotesRASP/Sources/` — app code.
- `Vendor/GRDB.swift/` — vendored, SQLCipher-patched GRDB fork (tests/docs from
  upstream trimmed; only what's needed to build is kept).

## Building

```bash
tuist install
tuist generate
```

Then build/run `SecureNotesRASP.xcworkspace` (iOS 16+ Simulator or device).
