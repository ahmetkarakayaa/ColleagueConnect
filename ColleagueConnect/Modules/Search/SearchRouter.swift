
import UIKit

final class SearchRouter: SearchRouterInput {

    weak var viewController: UIViewController?

    static func createModule() -> UIViewController {

        let view = SearchViewController()
        let interactor = SearchInteractor()
        let router = SearchRouter()

        let presenter = SearchPresenter(
            interactor: interactor,
            router: router
        )

        view.presenter = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

    
    func showUserDetail(username: String) {
        let detailViewController = UserDetailRouter.createModule(
            username: username
        )

        viewController?.navigationController?.pushViewController(
            detailViewController,
            animated: true
        )
    }

}
