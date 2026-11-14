
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

    func requestStatus(
        endpoint: APIEndpoint
    ) async throws -> Int
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
            (data, response) = try await session.data(
                for: request
            )
        } catch {
            throw classifyConnectionError(error)
        }

        try Task.checkCancellation()

        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        try validateResponse(
            response,
            data: data
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(
            T.self,
            from: data
        )
    }

    func requestStatus(
        endpoint: APIEndpoint
    ) async throws -> Int {

        var request = try endpoint.makeURLRequest()
        request.timeoutInterval = 12

        if request.httpMethod == "PUT",
           request.httpBody == nil {

            request.httpBody = Data()
            request.setValue(
                "0",
                forHTTPHeaderField: "Content-Length"
            )
        }

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(
                for: request
            )
        } catch {
            throw classifyConnectionError(error)
        }

        try Task.checkCancellation()

        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        let statusCode = response.statusCode

#if DEBUG
print("GitHub API Method:", request.httpMethod ?? "Unknown")
print("GitHub API Path:", request.url?.path ?? "Unknown")
print("GitHub API Status:", statusCode)

if let scopes = response.value(
    forHTTPHeaderField: "X-OAuth-Scopes"
) {
    print("GitHub OAuth Scopes:", scopes)
}

if statusCode >= 400 {
    let message = String(
        data: data,
        encoding: .utf8
    ) ?? "No response body"

    print("GitHub API Error:", message)
}
#endif


        if statusCode == 404,
           endpoint.method == "GET",
           endpoint.path.hasPrefix("/user/following/") {
            return 404
        }

        try validateResponse(
            response,
            data: data
        )

        return statusCode
    }

    private func classifyConnectionError(
        _ error: Error
    ) -> Error {

        if Task.isCancelled {
            return CancellationError()
        }

        guard let urlError = error as? URLError else {
            return error
        }

        switch urlError.code {

        case .notConnectedToInternet,
             .networkConnectionLost,
             .dataNotAllowed:
            return NetworkError.offline

        case .cancelled:
            return CancellationError()

        default:
            return urlError
        }
    }

    private func validateResponse(
        _ response: HTTPURLResponse,
        data: Data
    ) throws {

        guard (200...299).contains(response.statusCode) else {

            if response.statusCode == 429 {
                throw NetworkError.rateLimited
            }

            if response.statusCode == 403 {

                let remaining = response.value(
                    forHTTPHeaderField: "X-RateLimit-Remaining"
                )

                let apiMessage = (
                    try? JSONSerialization.jsonObject(
                        with: data
                    )
                ) as? [String: Any]

                let message = (
                    apiMessage?["message"] as? String
                )?.lowercased() ?? ""

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
    }
}
