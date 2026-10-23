
import Foundation


enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case offline
}


protocol NetworkClientProtocol {
    func request<T: Decodable>(
        endpoint: APIEndpoint
    ) async throws -> T
}

final class NetworkClient: NetworkClientProtocol {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(
        endpoint: APIEndpoint
    ) async throws -> T {

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = endpoint.path
        components.queryItems = endpoint.queryItems.isEmpty
            ? nil
            : endpoint.queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "2022-11-28",
            forHTTPHeaderField: "X-GitHub-Api-Version"
        )

        
        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .dataNotAllowed:
                throw NetworkError.offline

            case .cancelled:
                throw CancellationError()

            default:
                throw error
            }
        }


        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(response.statusCode) else {
            throw NetworkError.httpError(
                statusCode: response.statusCode
            )
        }

       
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)

    }
}
