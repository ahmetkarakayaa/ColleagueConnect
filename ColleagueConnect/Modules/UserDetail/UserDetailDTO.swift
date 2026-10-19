import Foundation

struct UserDetailDTO: Decodable {

    let id: Int
    let login: String
    let name: String?
    let avatarURL: URL?
    let bio: String?
    let followers: Int
    let following: Int
    let createdAt: Date
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case name
        case bio
        case followers
        case following
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case htmlURL = "html_url"
    }

    func toEntity() -> UserDetailEntity {
        UserDetailEntity(
            id: id,
            login: login,
            name: name,
            avatarURL: avatarURL,
            bio: bio,
            followers: followers,
            following: following,
            createdAt: createdAt,
            htmlURL: htmlURL
        )
    }
}
