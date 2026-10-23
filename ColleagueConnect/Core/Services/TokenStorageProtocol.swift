
import Foundation

protocol TokenStorageProtocol {
    func saveToken(_ token: String) throws
    func getToken() throws -> String?
    func deleteToken() throws
}

