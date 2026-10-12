
import UIKit

final class AppRouter {

    func makeInitialViewController() -> UIViewController {
        return WelcomeRouter.createModule()
    }
}

