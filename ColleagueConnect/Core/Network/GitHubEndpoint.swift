
import Foundation

enum GitHubEndpoint: APIEndpoint {

    case searchUsers(query: String)
    case userDetail(username: String)
    case authenticatedUser(token: String)
    case authenticatedUserDetail(username: String, token: String)

    var path: String {
        switch self {
        case .searchUsers:
            return "/search/users"

        case .userDetail(let username),
             .authenticatedUserDetail(let username, _):
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

    var headers: [String: String] {
        var headers: [String: String] = [
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        ]

        switch self {
        case .authenticatedUser(let token),
             .authenticatedUserDetail(_, let token):
            headers["Authorization"] = "Bearer \(token)"

        default:
            break
        }

        return headers
    }
}
