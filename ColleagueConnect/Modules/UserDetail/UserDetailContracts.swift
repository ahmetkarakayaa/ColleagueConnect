
import UIKit

@MainActor
protocol UserDetailViewInput: AnyObject {
    func displayLoading()
    func displayUser(_ user: UserDetailEntity, isFavorite: Bool)
    func displayError(_ message: String)
}

@MainActor
protocol UserDetailViewOutput: AnyObject {
    func viewDidLoad()
    func didTapFavorite()
    func didTapGitHub()
}

protocol UserDetailInteractorInput {
    func fetchUser(username: String) async throws -> UserDetailEntity
    func isFavorite(username: String) -> Bool
    func toggleFavorite(username: String) -> Bool
}

@MainActor
protocol UserDetailRouterInput: AnyObject {
    func openGitHubProfile(_ url: URL)
}
