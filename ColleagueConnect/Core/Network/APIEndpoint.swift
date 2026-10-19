
import Foundation

protocol APIEndpoint {
    var path: String { get }
    var method: String { get }
    var queryItems: [URLQueryItem] { get }
}

extension APIEndpoint {

    var method: String {
        return "GET"
    }

    var queryItems: [URLQueryItem] {
        return []
    }
}
