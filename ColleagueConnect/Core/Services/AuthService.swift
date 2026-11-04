
import Foundation

enum AuthError: Error {
    case invalidAuthorizationURL
    case invalidCallback
    case missingAuthorizationCode
    case invalidState
    case authorizationFailed(String)
    case invalidResponse
    case httpError(Int)
    case missingAccessToken
}

protocol AuthServiceProtocol {
    func makeAuthorizationURL() throws -> URL
    func handleCallback(_ url: URL) async throws
    func isLoggedIn() throws -> Bool
    func accessToken() throws -> String?
    func signOut() throws
}

final class AuthService: AuthServiceProtocol {

    private let configuration: OAuthConfiguration
    private let tokenStorage: TokenStorageProtocol
    private let networkClient: NetworkClientProtocol
    private let callbackParser: OAuthCallbackParser

    private var pendingState: String?

    init(
        configuration: OAuthConfiguration,
        tokenStorage: TokenStorageProtocol,
        networkClient: NetworkClientProtocol
    ) {
        self.configuration = configuration
        self.tokenStorage = tokenStorage
        self.networkClient = networkClient
        self.callbackParser = OAuthCallbackParser(
            redirectURI: configuration.redirectURI
        )
    }

    func makeAuthorizationURL() throws -> URL {
        let state = UUID().uuidString

        let endpoint = GitHubAuthEndpoint(
            configuration: configuration
        )

        let url = try endpoint.authorizationURL(
            state: state
        )

        pendingState = state
        return url
    }

    func handleCallback(_ url: URL) async throws {
        let code = try callbackParser.authorizationCode(
            from: url,
            expectedState: pendingState
        )

        pendingState = nil

        let token = try await exchangeCodeForToken(code)
        try tokenStorage.saveToken(token)
    }

    func isLoggedIn() throws -> Bool {
        guard let token = try tokenStorage.getToken() else {
            return false
        }

        return !token.isEmpty
    }

    func accessToken() throws -> String? {
        try tokenStorage.getToken()
    }

    func signOut() throws {
        pendingState = nil
        try tokenStorage.deleteToken()
    }

    private func exchangeCodeForToken(
        _ code: String
    ) async throws -> String {

        let endpoint = GitHubAuthEndpoint(
            configuration: configuration,
            code: code
        )

        let result: GitHubTokenResponse

        do {
            result = try await networkClient.request(
                endpoint: endpoint
            )
        } catch NetworkError.invalidURL {
            throw AuthError.invalidAuthorizationURL
        } catch NetworkError.invalidResponse {
            throw AuthError.invalidResponse
        } catch NetworkError.httpError(let statusCode) {
            throw AuthError.httpError(statusCode)
        } catch is DecodingError {
            throw AuthError.invalidResponse
        }

        if let error = result.error {
            throw AuthError.authorizationFailed(error)
        }

        guard let token = result.accessToken,
              !token.isEmpty else {
            throw AuthError.missingAccessToken
        }

        return token
    }
}

struct GitHubTokenResponse: Decodable {
    let accessToken: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case error
    }
}
