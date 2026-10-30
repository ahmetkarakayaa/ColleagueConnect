import Foundation

struct SearchUserEntity {
    let id: Int
    let username: String
    let avatarURL: URL
}

struct SearchUserViewModel: Hashable {
    let id: Int
    let username: String
    let avatarURL: URL
}
