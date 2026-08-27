import Foundation
import Security

enum PassphraseStore {
    private static let service = "com.kanat.securenotesrasp.sqlcipher"
    private static let account = "passphrase"

    enum StoreError: Error {
        case unexpectedStatus(OSStatus)
        case unreadableData
    }

    static func loadOrCreatePassphrase() throws -> String {
        if let existing = try readPassphrase() {
            return existing
        }
        let generated = UUID().uuidString
        try savePassphrase(generated)
        return generated
    }

    private static func readPassphrase() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
                throw StoreError.unreadableData
            }
            return string
        case errSecItemNotFound:
            return nil
        default:
            throw StoreError.unexpectedStatus(status)
        }
    }

    private static func savePassphrase(_ passphrase: String) throws {
        guard let data = passphrase.data(using: .utf8) else {
            throw StoreError.unreadableData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw StoreError.unexpectedStatus(status)
        }
    }
}
