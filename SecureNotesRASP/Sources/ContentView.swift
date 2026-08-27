import SwiftUI
import GRDB

struct ContentView: View {
    @State private var plaintextDump = ""
    @State private var encryptedDump = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SQLCipher Encryption Proof")
                .font(.title2.bold())

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }

            HStack(alignment: .top, spacing: 12) {
                DumpColumn(title: "Plaintext SQLite", subtitle: "readable on disk", text: plaintextDump)
                DumpColumn(title: "SQLCipher DB", subtitle: "random-looking bytes", text: encryptedDump)
            }

            Spacer()
        }
        .padding()
        .task {
            do {
                try seedAndDump()
            } catch {
                errorMessage = "\(error)"
            }
        }
    }

    private func seedAndDump() throws {
        let note = SecureNote(id: nil, text: "тест Batman")

        let encrypted = try DatabaseManager.openDatabase()
        try encrypted.write { db in
            if try SecureNote.fetchCount(db) == 0 {
                try note.insert(db)
            }
        }

        let plaintext = try DatabaseManager.openPlaintextDemoDatabase()
        try plaintext.write { db in
            if try SecureNote.fetchCount(db) == 0 {
                try note.insert(db)
            }
        }

        let plaintextPath = try DatabaseManager.plaintextDemoPath()
        let plaintextData = try Data(contentsOf: URL(fileURLWithPath: plaintextPath))
        let encryptedData = try Data(contentsOf: URL(fileURLWithPath: DatabaseManager.encryptedPath()))

        // The row lives near the end of SQLite's page, not in the header —
        // jump straight to the "тест" bytes so the note text is on screen.
        let needle = Array("тест".utf8)
        let offset = Self.findOffset(of: needle, in: plaintextData) ?? 0

        plaintextDump = Self.hexAsciiDump(of: plaintextData, around: offset, leadingContext: 16, window: 400)
        encryptedDump = Self.hexAsciiDump(of: encryptedData, around: offset, leadingContext: 16, window: 400)
    }

    private static func findOffset(of needle: [UInt8], in data: Data) -> Int? {
        let bytes = Array(data)
        guard !needle.isEmpty, bytes.count >= needle.count else { return nil }
        for start in 0...(bytes.count - needle.count) {
            if Array(bytes[start..<start + needle.count]) == needle {
                return start
            }
        }
        return nil
    }

    private static func hexAsciiDump(of data: Data, around offset: Int, leadingContext: Int, window: Int) -> String {
        let start = max(0, offset - leadingContext)
        let end = min(data.count, start + window)
        return hexAsciiDump(bytes: Array(data[start..<end]))
    }

    private static func hexAsciiDump(ofFileAt path: String, limit: Int) throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return hexAsciiDump(bytes: Array(data.prefix(limit)))
    }

    private static func hexAsciiDump(bytes: [UInt8]) -> String {
        var lines: [String] = []
        for rowStart in stride(from: 0, to: bytes.count, by: 8) {
            let row = bytes[rowStart..<min(rowStart + 8, bytes.count)]
            let hex = row.map { String(format: "%02x", $0) }.joined(separator: " ")
            let ascii = row.map { (32..<127).contains($0) ? String(UnicodeScalar($0)) : "." }.joined()
            lines.append(hex.padding(toLength: 24, withPad: " ", startingAt: 0) + " " + ascii)
        }
        return lines.joined(separator: "\n")
    }
}

private struct DumpColumn: View {
    let title: String
    let subtitle: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            ScrollView {
                Text(text)
                    .font(.system(.caption2, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 480)
            .padding(6)
            .background(Color.black.opacity(0.05))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
