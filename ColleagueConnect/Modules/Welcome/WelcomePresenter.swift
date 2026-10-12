
import Foundation

final class WelcomePresenter: WelcomeViewOutput {

    weak var view: WelcomeViewInput?
    private let interactor: WelcomeInteractorInput

    init(interactor: WelcomeInteractorInput) {
        self.interactor = interactor
    }

    func viewDidLoad() {
        let message = interactor.fetchWelcomeMessage()
        view?.displayWelcomeMessage(message.text)
    }
}
