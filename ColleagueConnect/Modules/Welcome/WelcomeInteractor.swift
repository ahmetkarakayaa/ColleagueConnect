
import Foundation

final class WelcomeInteractor: WelcomeInteractorInput {

    func fetchWelcomeMessage() -> WelcomeMessage {
        return WelcomeMessage(
            text: "Welcome to Colleague Connect"
        )
    }
}
