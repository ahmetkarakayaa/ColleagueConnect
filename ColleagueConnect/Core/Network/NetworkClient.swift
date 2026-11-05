
import Foundation



enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case rateLimited
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


        var request = try endpoint.makeURLRequest()
        request.timeoutInterval = 12
        
        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }

            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet,
                     .networkConnectionLost,
                     .dataNotAllowed:
                    throw NetworkError.offline

                case .cancelled:
                    throw CancellationError()

                default:
                    throw urlError
                }
            }

            throw error
        }
        
        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

       
        guard (200...299).contains(response.statusCode) else {
            if response.statusCode == 429 {
                throw NetworkError.rateLimited
            }

            if response.statusCode == 403 {
                let remaining = response.value(
                    forHTTPHeaderField: "X-RateLimit-Remaining"
                )

                let apiMessage = (
                    try? JSONSerialization.jsonObject(with: data)
                ) as? [String: Any]

                let message = (apiMessage?["message"] as? String)?
                    .lowercased() ?? ""

                if remaining == "0"
                    || message.contains("rate limit")
                    || message.contains("secondary rate") {
                    throw NetworkError.rateLimited
                }
            }

            throw NetworkError.httpError(
                statusCode: response.statusCode
            )
        }


        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(T.self, from: data)
    }
}
