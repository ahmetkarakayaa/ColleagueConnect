
import XCTest
@testable import ColleagueConnect

final class KeychainTokenStorageTests: XCTestCase {

    private var storage: KeychainTokenStorage!

    override func setUpWithError() throws {
        try super.setUpWithError()

        storage = KeychainTokenStorage(
            service: "com.colleagueconnect.tests.\(UUID().uuidString)",
            account: "test_github_access_token"
        )
    }

    override func tearDownWithError() throws {
        if let storage {
            try storage.deleteToken()
        }

        storage = nil
        try super.tearDownWithError()
    }

    func testGetTokenWhenEmptyReturnsNil() throws {
        XCTAssertNil(try storage.getToken())
    }

    func testSaveAndGetToken() throws {
        let expectedToken = "test_access_token_123"

        try storage.saveToken(expectedToken)

        XCTAssertEqual(
            try storage.getToken(),
            expectedToken
        )
    }

    func testSaveTokenUpdatesExistingToken() throws {
        try storage.saveToken("old_token")
        try storage.saveToken("new_token")

        XCTAssertEqual(
            try storage.getToken(),
            "new_token"
        )
    }

    func testDeleteToken() throws {
        try storage.saveToken("test_token")
        try storage.deleteToken()

        XCTAssertNil(try storage.getToken())
    }

    func testDeleteTokenWhenEmptyDoesNotThrow() {
        XCTAssertNoThrow(try storage.deleteToken())
    }

    func testSaveEmptyTokenThrows() {
        XCTAssertThrowsError(
            try storage.saveToken("")
        ) { error in
            guard case TokenStorageError.invalidToken = error else {
                XCTFail("Expected invalidToken error")
                return
            }
        }
    }
}
