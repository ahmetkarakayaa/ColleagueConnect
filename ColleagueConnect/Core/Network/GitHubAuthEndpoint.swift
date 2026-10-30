
import Foundation

struct GitHubAuthEndpoint: APIEndpoint {

    let configuration: OAuthConfiguration
    let code: String?

    init(
        configuration: OAuthConfiguration,
        code: String? = nil
    ) {
        self.configuration = configuration
        self.code = code
    }

    var host: String {
        "github.com"
    }

    var path: String {
        "/login/oauth/access_token"
    }

    var method: String {
        "POST"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    var headers: [String: String] {
        [
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
    }

    var body: Data? {
        guard let code else {
            return nil
        }

        var components = URLComponents()
        components.queryItems = [
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

        return components.percentEncodedQuery?
            .data(using: .utf8)
    }

    func authorizationURL(state: String) throws -> URL {
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

    func tokenRequest(code: String) throws -> URLRequest {
        let endpoint = GitHubAuthEndpoint(
            configuration: configuration,
            code: code
        )

        return try endpoint.makeURLRequest()
    }
}
