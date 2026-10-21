
import Foundation
import Security

enum TokenStorageError: Error {
    case invalidToken
    case unexpectedData
    case keychainError(OSStatus)
}

final class KeychainTokenStorage: TokenStorageProtocol {

    private let service: String
    private let account: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "ColleagueConnect",
        account: String = "github_access_token"
    ) {
        self.service = service
        self.account = account
    }

    func saveToken(_ token: String) throws {
        guard !token.isEmpty,
              let data = token.data(using: .utf8) else {
            throw TokenStorageError.invalidToken
        }

        let query = baseQuery()

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw TokenStorageError.keychainError(updateStatus)
        }

        var addQuery = query
        addQuery.merge(attributes) { _, new in new }

        let addStatus = SecItemAdd(
            addQuery as CFDictionary,
            nil
        )

        guard addStatus == errSecSuccess else {
            throw TokenStorageError.keychainError(addStatus)
        }
    }

    func getToken() throws -> String? {
        var query = baseQuery()

        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw TokenStorageError.keychainError(status)
        }

        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw TokenStorageError.unexpectedData
        }

        return token
    }

    func deleteToken() throws {
        let status = SecItemDelete(
            baseQuery() as CFDictionary
        )

        guard status == errSecSuccess ||
              status == errSecItemNotFound else {
            throw TokenStorageError.keychainError(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
