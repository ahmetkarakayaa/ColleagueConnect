
import Foundation

@MainActor
protocol FollowStatusStoreProtocol: AnyObject {

    func status(for username: String) -> Bool?

    func setStatus(
        _ isFollowing: Bool,
        for username: String
    )

    func revision(for username: String) -> Int

    func currentSessionVersion() -> Int

    func setStatusIfUnchanged(
        _ isFollowing: Bool,
        for username: String,
        expectedRevision: Int,
        expectedSessionVersion: Int
    ) -> Bool

    func setStatusIfCurrentSession(
        _ isFollowing: Bool,
        for username: String,
        expectedSessionVersion: Int
    ) -> Bool

    func shouldRefreshStatus(for username: String) -> Bool

    func currentGeneration() -> Int

    func cacheFollowingUsers(
        _ usernames: [String],
        expectedGeneration: Int
    )

    func clear()
}

@MainActor
final class FollowStatusStore: FollowStatusStoreProtocol {

    private var statuses: [String: Bool] = [:]
    private var revisions: [String: Int] = [:]
    private var lastUpdated: [String: Date] = [:]

    private var generation = 0
    private var sessionVersion = 0

    private let refreshInterval: TimeInterval = 120

    private func key(for username: String) -> String {
        username.lowercased()
    }

    func status(for username: String) -> Bool? {
        statuses[key(for: username)]
    }

    func revision(for username: String) -> Int {
        revisions[key(for: username), default: 0]
    }

    func currentGeneration() -> Int {
        generation
    }

    func currentSessionVersion() -> Int {
        sessionVersion
    }

    func shouldRefreshStatus(for username: String) -> Bool {
        let normalized = key(for: username)

        guard let updatedAt = lastUpdated[normalized] else {
            return true
        }

        return Date().timeIntervalSince(updatedAt) >= refreshInterval
    }

    func setStatus(
        _ isFollowing: Bool,
        for username: String
    ) {
        let normalized = key(for: username)

        statuses[normalized] = isFollowing
        lastUpdated[normalized] = Date()

        revisions[normalized, default: 0] += 1
        generation += 1
    }

    func setStatusIfUnchanged(
        _ isFollowing: Bool,
        for username: String,
        expectedRevision: Int,
        expectedSessionVersion: Int
    ) -> Bool {

        guard sessionVersion == expectedSessionVersion,
              revision(for: username) == expectedRevision else {
            return false
        }

        setStatus(isFollowing, for: username)
        return true
    }

    func setStatusIfCurrentSession(
        _ isFollowing: Bool,
        for username: String,
        expectedSessionVersion: Int
    ) -> Bool {

        guard sessionVersion == expectedSessionVersion else {
            return false
        }

        setStatus(isFollowing, for: username)
        return true
    }

    func cacheFollowingUsers(
        _ usernames: [String],
        expectedGeneration: Int
    ) {
        guard generation == expectedGeneration else {
            return
        }

        for username in usernames {
            let normalized = key(for: username)

            if statuses[normalized] == false {
                continue
            }

            statuses[normalized] = true
            lastUpdated[normalized] = Date()
            revisions[normalized, default: 0] += 1
        }
    }

    func clear() {
        statuses.removeAll()
        revisions.removeAll()
        lastUpdated.removeAll()

        generation += 1
        sessionVersion += 1
    }
}
