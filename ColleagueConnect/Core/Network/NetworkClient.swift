
import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
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

        let request = try endpoint.makeURLRequest()

        let (data, response) = try await session.data(
            for: request
        )

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
