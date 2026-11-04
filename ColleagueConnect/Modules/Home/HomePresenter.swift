
import Foundation

@MainActor
final class HomePresenter: HomeViewOutput {

    weak var view: HomeViewInput?

    private let interactor: HomeInteractorInput
    private var loadTask: Task<Void, Never>?

    init(interactor: HomeInteractorInput) {
        self.interactor = interactor
    }

    func viewDidLoad() {
        loadProfile()
    }

    func didTapRetry() {
        loadProfile()
    }

    private func loadProfile() {
        loadTask?.cancel()
        view?.displayLoading()

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let user = try await interactor.fetchCurrentUser()

                guard !Task.isCancelled else { return }

                let model = HomeViewModel(
                    name: user.name ?? user.login,
                    username: "@\(user.login)",
                    bio: user.bio,
                    avatarURL: user.avatarURL,
                    followers: user.followers.formatted(),
                    following: user.following.formatted(),
                    profileURL: user.htmlURL
                )

                view?.displayProfile(model)
            } catch {
                guard !Task.isCancelled else { return }

                view?.displayError(
                    "Couldn't load your profile. Please try again."
                )
            }
        }
    }

    deinit {
        loadTask?.cancel()
    }
}
