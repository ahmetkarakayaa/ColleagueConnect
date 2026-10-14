
import Foundation

@MainActor
protocol SearchViewInput: AnyObject {
    func displayUsers(_ users: [SearchUserViewModel])
    func displayLoading()
    func displayEmpty()
    func displayError(_ message: String)
}

@MainActor
protocol SearchViewOutput: AnyObject {
    func searchUsers(query: String)
    func didSelectUser(_ user: SearchUserViewModel)

    func toggleFavorite(username: String)
    func isFavorite(username: String) -> Bool
}

protocol SearchInteractorInput {
    func searchUsers(query: String) async throws -> [GitHubUser]

    func toggleFavorite(username: String)
    func isFavorite(username: String) -> Bool
}

@MainActor
protocol SearchRouterInput: AnyObject {
    func showUserDetail(username: String)
}
