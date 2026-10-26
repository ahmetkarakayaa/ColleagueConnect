import Foundation

protocol WelcomeViewInput: AnyObject {
    func displayWelcomeMessage(_ message: String)
    func setLoading(_ isLoading: Bool)
    func displayError(_ message: String)
}

protocol WelcomeViewOutput: AnyObject {
    func viewDidLoad()
}

protocol WelcomeInteractorInput {
    func fetchWelcomeMessage() -> WelcomeMessage
}
