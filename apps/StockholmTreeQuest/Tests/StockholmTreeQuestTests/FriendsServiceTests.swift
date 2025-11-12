import XCTest
@testable import StockholmTreeQuest

@MainActor
final class FriendsServiceTests: XCTestCase {
    func testRefreshPopulatesFriendsFromLoader() async {
        let stubFriends = [
            Friend(
                id: "friend-1",
                displayName: "Snow Scout",
                avatar: "🎄",
                totalTrees: 12,
                city: "North Pole",
                visits: [],
                lastActive: Date()
            )
        ]
        let service = FriendsService(authenticationProvider: { true }, loader: { stubFriends })

        await service.refresh()

        XCTAssertTrue(service.isAuthenticated)
        XCTAssertEqual(service.friends.count, 1)
        XCTAssertEqual(service.friends.first?.displayName, "Snow Scout")
    }

    func testFriendLookupReturnsMatchingFriend() async {
        let stubFriends = [
            Friend(
                id: "friend-1",
                displayName: "Snow Scout",
                avatar: "🎄",
                totalTrees: 12,
                city: "North Pole",
                visits: [],
                lastActive: Date()
            )
        ]
        let service = FriendsService(authenticationProvider: { true }, loader: { stubFriends })

        await service.refresh()

        let fetched = service.friend(for: "friend-1")
        XCTAssertEqual(fetched?.displayName, "Snow Scout")
    }
}
