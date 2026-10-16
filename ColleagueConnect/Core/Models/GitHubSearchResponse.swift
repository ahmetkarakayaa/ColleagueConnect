import Foundation

struct GitHubSearchResponse: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [GitHubUserResponse]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}
