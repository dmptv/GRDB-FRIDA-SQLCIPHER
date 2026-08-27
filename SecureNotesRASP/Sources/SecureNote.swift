import GRDB

struct SecureNote: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "secureNote"

    var id: Int64?
    var text: String

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
