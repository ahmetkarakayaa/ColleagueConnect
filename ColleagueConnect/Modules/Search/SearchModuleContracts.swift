
import Foundation
enum SearchDisplayError {
    case offline
    case general
}

@MainActor
protocol SearchViewInput: AnyObject {
    func displayUsers(_ users: [SearchUserViewModel])
    func displayLoading()
    func displayEmpty()
    func displayError(_ error: SearchDisplayError)

    func displayUserDetails(
        username: String,
        name: String?,
        bio: String?
    )
}

@MainActor
protocol SearchViewOutput: AnyObject {
    func searchUsers(query: String)
    func didSelectUser(_ user: SearchUserViewModel)

    func toggleFavorite(username: String)
    func isFavorite(username: String) -> Bool

    func loadUserDetails(username: String)
}


protocol SearchInteractorInput {
    func searchUsers(query: String) async throws -> [SearchUserEntity]

    func fetchUserDetails(
        username: String
    ) async throws -> UserDetailEntity

    func toggleFavorite(username: String)
    func isFavorite(username: String) -> Bool
}

@MainActor
protocol SearchRouterInput: AnyObject {
    func showUserDetail(username: String)
}
