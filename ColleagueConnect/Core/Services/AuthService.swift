
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
    private let session: URLSession

    private var pendingState: String?

    init(
        configuration: OAuthConfiguration,
        tokenStorage: TokenStorageProtocol,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.tokenStorage = tokenStorage
        self.session = session
    }

    func makeAuthorizationURL() throws -> URL {
        let state = UUID().uuidString
        pendingState = state

        var components = URLComponents()
        components.scheme = "https"
        components.host = "github.com"
        components.path = "/login/oauth/authorize"
        components.queryItems = [
            URLQueryItem(
                name: "client_id",
                value: configuration.clientID
            ),
            URLQueryItem(
                name: "redirect_uri",
                value: configuration.redirectURI
            ),
            URLQueryItem(
                name: "state",
                value: state
            )
        ]

        guard let url = components.url else {
            throw AuthError.invalidAuthorizationURL
        }

        return url
    }

    func handleCallback(_ url: URL) async throws {
        guard let expectedURL = URL(
            string: configuration.redirectURI
        ),
        url.scheme == expectedURL.scheme,
        url.host == expectedURL.host,
        url.path == expectedURL.path else {
            throw AuthError.invalidCallback
        }

        guard let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            throw AuthError.invalidCallback
        }

        let items = components.queryItems ?? []

        func parameter(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        guard let expectedState = pendingState,
              let receivedState = parameter("state"),
              receivedState == expectedState else {
            throw AuthError.invalidState
        }

        // A callback is valid only once.
        pendingState = nil

        if let error = parameter("error") {
            throw AuthError.authorizationFailed(error)
        }

        guard let code = parameter("code"),
              !code.isEmpty else {
            throw AuthError.missingAuthorizationCode
        }

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

        guard let url = URL(
            string: "https://github.com/login/oauth/access_token"
        ) else {
            throw AuthError.invalidAuthorizationURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(
                name: "client_id",
                value: configuration.clientID
            ),
            URLQueryItem(
                name: "client_secret",
                value: configuration.clientSecret
            ),
            URLQueryItem(
                name: "code",
                value: code
            ),
            URLQueryItem(
                name: "redirect_uri",
                value: configuration.redirectURI
            )
        ]

        request.httpBody = body.percentEncodedQuery?
            .data(using: .utf8)

        let (data, response) = try await session.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.httpError(
                httpResponse.statusCode
            )
        }

        let result = try JSONDecoder().decode(
            GitHubTokenResponse.self,
            from: data
        )

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

private struct GitHubTokenResponse: Decodable {
    let accessToken: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case error
    }
}
