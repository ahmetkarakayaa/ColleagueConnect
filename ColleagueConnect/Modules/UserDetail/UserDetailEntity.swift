import Foundation
struct UserDetailEntity {
    let id: Int
    let login: String
    let name: String?
    let avatarURL: URL?
    let bio: String?
    let followers: Int
    let following: Int
    let createdAt: Date
    let htmlURL: URL
}
