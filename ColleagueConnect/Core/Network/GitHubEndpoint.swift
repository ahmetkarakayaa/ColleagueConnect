
import Foundation

enum GitHubEndpoint: APIEndpoint {

    case searchUsers(query: String)
    case userDetail(username: String)
    case authenticatedUser

    var path: String {
        switch self {
        case .searchUsers:
            return "/search/users"

        case .userDetail(let username):
            return "/users/\(username)"

        case .authenticatedUser:
            return "/user"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .searchUsers(let query):
            return [
                URLQueryItem(name: "q", value: query)
            ]

        default:
            return []
        }
    }
}
