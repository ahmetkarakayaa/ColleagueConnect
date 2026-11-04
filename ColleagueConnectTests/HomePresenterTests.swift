
import Foundation
import XCTest
@testable import ColleagueConnect

final class HomePresenterTests: XCTestCase {

    @MainActor
    func testViewDidLoadShowsLoading() {
        let interactor = HomeInteractorMock(user: makeUser())
        let presenter = HomePresenter(interactor: interactor)
        let view = HomeViewSpy()
        presenter.view = view

        presenter.viewDidLoad()

        XCTAssertEqual(view.loadingCount, 1)
    }

    @MainActor
    func testSuccessfulLoadDisplaysProfile() async {
        let interactor = HomeInteractorMock(user: makeUser())
        let presenter = HomePresenter(interactor: interactor)
        let view = HomeViewSpy()
        let completed = expectation(description: "Profile loaded")

        view.onProfile = {
            completed.fulfill()
        }

        presenter.view = view
        presenter.viewDidLoad()

        await fulfillment(of: [completed], timeout: 2)

        XCTAssertEqual(view.model?.name, "Test User")
        XCTAssertEqual(view.model?.username, "@testuser")
        XCTAssertEqual(view.model?.followers, "120")
        XCTAssertEqual(view.model?.following, "45")
        XCTAssertEqual(interactor.callCount, 1)
    }

    @MainActor
    func testFailedLoadDisplaysError() async {
        let interactor = HomeInteractorMock(user: makeUser())
        interactor.shouldFail = true

        let presenter = HomePresenter(interactor: interactor)
        let view = HomeViewSpy()
        let completed = expectation(description: "Error displayed")

        view.onError = {
            completed.fulfill()
        }

        presenter.view = view
        presenter.viewDidLoad()

        await fulfillment(of: [completed], timeout: 2)

        XCTAssertNotNil(view.errorMessage)
        XCTAssertNil(view.model)
    }

    @MainActor
    func testRetryFetchesProfileAgain() async {
        let interactor = HomeInteractorMock(user: makeUser())
        interactor.shouldFail = true

        let presenter = HomePresenter(interactor: interactor)
        let view = HomeViewSpy()
        let failed = expectation(description: "Initial failure")

        view.onError = {
            failed.fulfill()
        }

        presenter.view = view
        presenter.viewDidLoad()

        await fulfillment(of: [failed], timeout: 2)

        interactor.shouldFail = false

        let succeeded = expectation(description: "Retry succeeded")
        view.onProfile = {
            succeeded.fulfill()
        }

        presenter.didTapRetry()

        await fulfillment(of: [succeeded], timeout: 2)

        XCTAssertEqual(interactor.callCount, 2)
        XCTAssertEqual(view.loadingCount, 2)
        XCTAssertEqual(view.model?.username, "@testuser")
    }

    private func makeUser() -> UserDetailEntity {
        UserDetailEntity(
            id: 1,
            login: "testuser",
            name: "Test User",
            avatarURL: nil,
            bio: "iOS Developer",
            followers: 120,
            following: 45,
            createdAt: Date(timeIntervalSince1970: 0),
            htmlURL: URL(string: "https://github.com/testuser")!
        )
    }
}

private final class HomeInteractorMock: HomeInteractorInput {

    let user: UserDetailEntity
    var shouldFail = false
    private(set) var callCount = 0

    init(user: UserDetailEntity) {
        self.user = user
    }

    func fetchCurrentUser() async throws -> UserDetailEntity {
        callCount += 1

        if shouldFail {
            throw NetworkError.invalidResponse
        }

        return user
    }
}

@MainActor
private final class HomeViewSpy: HomeViewInput {

    private(set) var loadingCount = 0
    private(set) var model: HomeViewModel?
    private(set) var errorMessage: String?

    var onProfile: (() -> Void)?
    var onError: (() -> Void)?

    func displayLoading() {
        loadingCount += 1
    }

    func displayProfile(_ model: HomeViewModel) {
        self.model = model
        onProfile?()
    }

    func displayError(_ message: String) {
        errorMessage = message
        onError?()
    }
}
