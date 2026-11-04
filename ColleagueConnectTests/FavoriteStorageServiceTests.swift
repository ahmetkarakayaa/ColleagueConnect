
import XCTest
@testable import ColleagueConnect

final class FavoriteStorageServiceTests: XCTestCase {

    private var defaults: UserDefaults!
    private var service: FavoriteStorageService!

    override func setUp() {
        super.setUp()

        defaults = UserDefaults(
            suiteName: "FavoriteStorageServiceTests"
        )

        defaults.removePersistentDomain(
            forName: "FavoriteStorageServiceTests"
        )

        service = FavoriteStorageService(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(
            forName: "FavoriteStorageServiceTests"
        )

        service = nil
        defaults = nil
        super.tearDown()
    }

    func testRecentFavoritesReturnsNewestFirst() {
        ["zeynep", "ali", "mehmet"].forEach {
            service.addFavorite(username: $0)
        }

        XCTAssertEqual(
            service.getRecentFavorites(limit: 2),
            ["mehmet", "ali"]
        )

        XCTAssertEqual(
            service.getFavorites(),
            ["ali", "mehmet", "zeynep"]
        )
    }

    func testDuplicateFavoriteDoesNotChangeOrder() {
        service.addFavorite(username: "ali")
        service.addFavorite(username: "zeynep")
        service.addFavorite(username: "ali")

        XCTAssertEqual(
            service.getRecentFavorites(limit: 5),
            ["zeynep", "ali"]
        )
    }

    func testRemovingFavoriteUpdatesRecentList() {
        service.addFavorite(username: "ali")
        service.addFavorite(username: "zeynep")

        service.removeFavorite(username: "zeynep")

        XCTAssertEqual(
            service.getRecentFavorites(limit: 5),
            ["ali"]
        )
    }

    func testExistingFavoritesArePreserved() {
        defaults.set(
            ["ali", "mehmet", "zeynep"],
            forKey: "favorite_usernames"
        )

        XCTAssertEqual(service.getFavorites().count, 3)
        XCTAssertEqual(service.getRecentFavorites(limit: 5).count, 3)
    }

    func testZeroLimitReturnsEmptyList() {
        service.addFavorite(username: "ali")

        XCTAssertTrue(
            service.getRecentFavorites(limit: 0).isEmpty
        )
    }
}
