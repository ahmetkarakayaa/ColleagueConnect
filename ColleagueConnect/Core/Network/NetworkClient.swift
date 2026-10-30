
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

        let request = try endpoint.makeURLRequest()

        
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
