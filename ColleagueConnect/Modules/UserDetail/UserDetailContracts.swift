
import UIKit

@MainActor
protocol UserDetailViewInput: AnyObject {

    func displayLoading()

    func displayUser(
        _ user: UserDetailEntity,
        isFavorite: Bool
    )

    func displayError(_ message: String)

    func displayFollowState(
        isFollowing: Bool,
        isLoading: Bool,
        isAvailable: Bool
    )

    func displayFollowError(_ message: String)

}

@MainActor
protocol UserDetailViewOutput: AnyObject {

    func viewDidLoad()

    func didTapFavorite()

    func didTapGitHub()

    func didTapFollow()

    func didTapUnfollow()

}

protocol UserDetailInteractorInput {

    func fetchUser(
        username: String
    ) async throws -> UserDetailEntity

    func isFavorite(username: String) -> Bool

    func toggleFavorite(username: String) -> Bool

    @MainActor
    func cachedFollowStatus(username: String) -> Bool?
    @MainActor
    func shouldRefreshFollowStatus(username: String) -> Bool


    func isFollowing(
        username: String
    ) async throws -> Bool

    func followUser(
        username: String
    ) async throws

    func unfollowUser(
        username: String
    ) async throws
}

@MainActor
protocol UserDetailRouterInput: AnyObject {

    func openGitHubProfile(_ url: URL)
}
