
import Foundation

enum GitHubEndpoint: APIEndpoint {

    case searchUsers(query: String)
    case userDetail(username: String)
    case authenticatedUser(token: String)
    case authenticatedUserDetail(username: String, token: String)

    case checkFollowing(username: String, token: String)
    case followUser(username: String, token: String)
    case unfollowUser(username: String, token: String)

    case followers(username: String, token: String, page: Int)
    case following(username: String, token: String, page: Int)

    var path: String {
        switch self {
        case .searchUsers:
            return "/search/users"

        case .userDetail(let username),
             .authenticatedUserDetail(let username, _):
            return "/users/\(username)"

        case .authenticatedUser:
            return "/user"

        case .checkFollowing(let username, _),
             .followUser(let username, _),
             .unfollowUser(let username, _):
            return "/user/following/\(username)"

        case .followers(let username, _, _):
            return "/users/\(username)/followers"

        case .following(let username, _, _):
            return "/users/\(username)/following"
        }
    }

    var method: String {
        switch self {
        case .followUser:
            return "PUT"

        case .unfollowUser:
            return "DELETE"

        default:
            return "GET"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .searchUsers(let query):
            return [
                URLQueryItem(name: "q", value: query)
            ]

        case .followers(_, _, let page),
             .following(_, _, let page):
            return [
                URLQueryItem(name: "per_page", value: "30"),
                URLQueryItem(name: "page", value: String(page))
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
             .authenticatedUserDetail(_, let token),
             .checkFollowing(_, let token),
             .followUser(_, let token),
             .unfollowUser(_, let token),
             .followers(_, let token, _),
             .following(_, let token, _):
            headers["Authorization"] = "Bearer \(token)"

        default:
            break
        }

        if case .followUser = self {
            headers["Content-Length"] = "0"
        }

        return headers
    }
}
