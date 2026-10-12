import Foundation

protocol WelcomeViewInput: AnyObject {
    func displayWelcomeMessage(_ message: String)
}

protocol WelcomeViewOutput: AnyObject {
    func viewDidLoad()
}

protocol WelcomeInteractorInput {
    func fetchWelcomeMessage() -> WelcomeMessage
}
