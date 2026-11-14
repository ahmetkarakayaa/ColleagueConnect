
import Foundation

enum FollowListType {
    case followers
    case following

    var title: String {
        switch self {
        case .followers:
            return "Followers"

        case .following:
            return "Following"
        }
    }
}

@MainActor
protocol FollowListViewInput: AnyObject {

    func displayLoading()

    func displayUsers(
        _ users: [FollowListUserViewModel]
    )

    func displayError(_ message: String)

    func displayPageError(_ message: String)
}

@MainActor
protocol FollowListViewOutput: AnyObject {
    func viewWillAppear()

    func viewDidLoad()

    func didSelectUser(at index: Int)

    func didReachEnd()
}

protocol FollowListInteractorInput {

    func fetchUsers(
        username: String,
        type: FollowListType,
        page: Int
    ) async throws -> [FollowListUserEntity]
}

@MainActor
protocol FollowListRouterInput: AnyObject {

    func openUserDetail(username: String)
}
