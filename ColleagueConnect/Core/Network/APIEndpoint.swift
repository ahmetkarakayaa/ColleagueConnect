
import Foundation

protocol APIEndpoint {
    var path: String { get }
    var method: String { get }
    var queryItems: [URLQueryItem] { get }
    var host: String { get }
    var headers: [String: String] { get }
    var body: Data? { get }
}

extension APIEndpoint {

    var method: String {
        "GET"
    }

    var queryItems: [URLQueryItem] {
        []
    }

    var host: String {
        "api.github.com"
    }

    var headers: [String: String] {
        [
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        ]
    }

    var body: Data? {
        nil
    }

    func makeURLRequest() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = queryItems.isEmpty
            ? nil
            : queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        for (name, value) in headers {
            request.setValue(
                value,
                forHTTPHeaderField: name
            )
        }

        request.httpBody = body
        return request
    }
}
