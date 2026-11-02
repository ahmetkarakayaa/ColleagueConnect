
import UIKit

@MainActor
final class HomeRouter {

    static func createModule(
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol
    ) -> UIViewController {
        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: authService
        )

        let presenter = HomePresenter(interactor: interactor)
        let viewController = HomeViewController()

        viewController.presenter = presenter
        presenter.view = viewController

        return viewController
    }
}
