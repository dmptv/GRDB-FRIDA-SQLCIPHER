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

## Part 2 — RASP (planned)

`IOSSecuritySuite` (`amIJailbroken`, `amIDebugged`, `amIReverseEngineered`) gates
access to the `SecureNote` store at `App.init()` — a compromised environment never
gets to open the encrypted database. Not yet implemented in this repo.

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
