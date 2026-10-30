
import Foundation

final class WelcomeInteractor: WelcomeInteractorInput {

    func fetchWelcomeMessage() -> WelcomeMessage {
        return WelcomeMessage(
            text: "Stay connected with your colleagues."        )
    }
}
