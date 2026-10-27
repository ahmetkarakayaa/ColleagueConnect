
import UIKit

@MainActor
final class AppRouter {

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func makeInitialViewController() -> UIViewController {
        WelcomeRouter.createModule(
            authService: authService
        )
    }
}
