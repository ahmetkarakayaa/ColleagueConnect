
import Foundation

@MainActor
protocol HomeViewInput: AnyObject {
    func displayLoading()
    func displayProfile(_ model: HomeViewModel)
    func displayError(_ message: String)
}

@MainActor
protocol HomeViewOutput: AnyObject {
    func viewDidLoad()
    func didTapRetry()
}

protocol HomeInteractorInput {
    func fetchCurrentUser() async throws -> UserDetailEntity
}
