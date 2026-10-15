import UIKit

@MainActor
final class UserDetailRouter: UserDetailRouterInput {

    weak var viewController: UIViewController?

    static func createModule(
        username: String,
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol
    ) -> UIViewController {
        let interactor = UserDetailInteractor(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage
        )

        let router = UserDetailRouter()

        let presenter = UserDetailPresenter(
            username: username,
            interactor: interactor,
            router: router
        )

        let viewController = UserDetailViewController()
        viewController.presenter = presenter

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    func openGitHubProfile(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
