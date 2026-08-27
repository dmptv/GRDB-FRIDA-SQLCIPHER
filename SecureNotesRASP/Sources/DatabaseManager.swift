import Foundation
import GRDB

enum DatabaseManager {
    static func openDatabase() throws -> DatabaseQueue {
        let passphrase = try PassphraseStore.loadOrCreatePassphrase()

        var configuration = Configuration()
        configuration.prepareDatabase { db in
            try db.usePassphrase(passphrase)
            // Demo only: keep writes in the main file (no separate -wal),
            // so a raw byte-dump of app.db always reflects the latest row.
            try db.execute(sql: "PRAGMA journal_mode = DELETE")
        }

        let dbQueue = try DatabaseQueue(path: try encryptedPath(), configuration: configuration)
        try migrator.migrate(dbQueue)

        return dbQueue
    }

    /// Demo-only: opens the same schema WITHOUT a passphrase, so its raw
    /// bytes on disk stay plaintext. Used side-by-side with the encrypted
    /// database to visually prove what SQLCipher actually buys us.
    static func openPlaintextDemoDatabase() throws -> DatabaseQueue {
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = DELETE")
        }

        let dbQueue = try DatabaseQueue(path: try plaintextDemoPath(), configuration: configuration)
        try migrator.migrate(dbQueue)
        return dbQueue
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createSecureNote") { db in
            try db.create(table: SecureNote.databaseTableName) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("text", .text).notNull()
            }
        }
        return migrator
    }

    static func encryptedPath() throws -> String {
        try supportDirectory().appendingPathComponent("app.db").path
    }

    static func plaintextDemoPath() throws -> String {
        try supportDirectory().appendingPathComponent("plain_demo.db").path
    }

    private static func supportDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }
}
