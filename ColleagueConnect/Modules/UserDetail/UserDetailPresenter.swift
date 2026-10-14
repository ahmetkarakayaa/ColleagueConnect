
import Foundation

@MainActor
final class UserDetailPresenter: UserDetailViewOutput {

    weak var view: UserDetailViewInput?

    private let interactor: UserDetailInteractorInput
    private let router: UserDetailRouterInput
    private let username: String

    private var user: UserDetailEntity?
    private var loadTask: Task<Void, Never>?

    init(
        username: String,
        interactor: UserDetailInteractorInput,
        router: UserDetailRouterInput
    ) {
        self.username = username
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        loadUser()
    }

    private func loadUser() {
        loadTask?.cancel()
        view?.displayLoading()

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let user = try await interactor.fetchUser(
                    username: username
                )

                guard !Task.isCancelled else { return }

                self.user = user

                view?.displayUser(
                    user,
                    isFavorite: interactor.isFavorite(
                        username: username
                    )
                )
            } catch {
                guard !Task.isCancelled else { return }
                view?.displayError(
                    "Couldn't load this profile. Please try again."
                )
            }
        }
    }

    func didTapFavorite() {
        guard let user else { return }

        let isFavorite = interactor.toggleFavorite(
            username: user.login
        )

        view?.displayUser(
            user,
            isFavorite: isFavorite
        )
    }

    func didTapGitHub() {
        guard let user else { return }
        router.openGitHubProfile(user.htmlURL)
    }

    deinit {
        loadTask?.cancel()
    }
}
