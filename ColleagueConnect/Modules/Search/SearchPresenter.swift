
import Foundation

@MainActor
final class SearchPresenter: SearchViewOutput {

    weak var view: SearchViewInput?

    private let interactor: SearchInteractorInput
    private let router: SearchRouterInput

    private var searchTask: Task<Void, Never>?

    init(
        interactor: SearchInteractorInput,
        router: SearchRouterInput
    ) {
        self.interactor = interactor
        self.router = router
    }

    func searchUsers(query: String) {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuery.isEmpty else {
            view?.displayEmpty()
            return
        }

        view?.displayLoading()

        searchTask = Task {
            do {
                let users = try await interactor.searchUsers(
                    query: trimmedQuery
                )

                guard !Task.isCancelled else { return }

                let viewModels = users.map { user in
                    SearchUserViewModel(
                        id: user.id,
                        username: user.login,
                        avatarURL: user.avatarURL
                    )
                }

                if viewModels.isEmpty {
                    view?.displayEmpty()
                } else {
                    view?.displayUsers(viewModels)
                }

            } catch {
                guard !Task.isCancelled else { return }

                view?.displayError(
                    "Kullanıcılar yüklenirken bir hata oluştu."
                )
            }
        }
    }

    func didSelectUser(_ user: SearchUserViewModel) {
        router.showUserDetail(username: user.username)
        
        

    }
    func toggleFavorite(username: String) {
        interactor.toggleFavorite(username: username)
    }

    func isFavorite(username: String) -> Bool {
        return interactor.isFavorite(username: username)
    }
}
