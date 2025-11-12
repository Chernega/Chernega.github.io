import XCTest
@testable import StockholmTreeQuest

@MainActor
final class FriendsServiceTests: XCTestCase {
    func testLoadPopulatesFriends() async {
        let service = FriendsService()
        await service.load()

        XCTAssertEqual(service.friends.count, 4)
        let totals = service.friends.map(\.totalTrees)
        XCTAssertTrue(totals.contains(64))
    }

    func testFriendLookupReturnsMatchingFriend() async {
        let service = FriendsService()
        await service.load()

        guard let first = service.friends.first else {
            XCTFail("Expected sample friends after load")
            return
        }

        let fetched = service.friend(for: first.id)
        XCTAssertEqual(fetched?.displayName, first.displayName)
    }
}
