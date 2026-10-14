
import Foundation

struct GitHubUser: Codable, Identifiable {
    let id: Int
    let login: String
    let avatarURL: URL
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}

struct GitHubSearchResponse: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [GitHubUser]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}
