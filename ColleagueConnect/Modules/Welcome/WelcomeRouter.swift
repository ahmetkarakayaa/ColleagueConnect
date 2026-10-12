
import UIKit

enum WelcomeRouter {

    static func createModule() -> UIViewController {
        let view = WelcomeViewController()
        let interactor = WelcomeInteractor()
        let presenter = WelcomePresenter(interactor: interactor)

        view.presenter = presenter
        presenter.view = view

        return view
    }
}
