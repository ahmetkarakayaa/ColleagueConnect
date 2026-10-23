
import Foundation
import Security
import KeychainSwift

enum TokenStorageError: Error {
    case invalidToken
    case unexpectedData
    case keychainError(OSStatus)
}

final class KeychainTokenStorage: TokenStorageProtocol {

    private let keychain: KeychainSwift
    private let tokenKey: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "ColleagueConnect",
        account: String = "github_access_token"
    ) {
        self.keychain = KeychainSwift()
        self.tokenKey = "\(service).\(account)"
    }

    func saveToken(_ token: String) throws {
        guard !token.isEmpty else {
            throw TokenStorageError.invalidToken
        }

        let saved = keychain.set(
            token,
            forKey: tokenKey,
            withAccess: .accessibleAfterFirstUnlockThisDeviceOnly
        )

        guard saved else {
            throw TokenStorageError.keychainError(
                keychain.lastResultCode
            )
        }
    }

    func getToken() throws -> String? {
        guard let data = keychain.getData(tokenKey) else {
            if keychain.lastResultCode == errSecItemNotFound {
                return nil
            }

            guard keychain.lastResultCode == errSecSuccess else {
                throw TokenStorageError.keychainError(
                    keychain.lastResultCode
                )
            }

            throw TokenStorageError.unexpectedData
        }

        guard let token = String(data: data, encoding: .utf8) else {
            throw TokenStorageError.unexpectedData
        }

        return token
    }

    func deleteToken() throws {
        let deleted = keychain.delete(tokenKey)

        guard deleted ||
              keychain.lastResultCode == errSecItemNotFound else {
            throw TokenStorageError.keychainError(
                keychain.lastResultCode
            )
        }
    }
}
