import XCTest
import MapKit
@testable import StockholmTreeQuest

@MainActor
final class ProfileViewModelTests: XCTestCase {
    private func makeStore(treeCount: Int) -> TreeStore {
        let store = TreeStore(persistHandler: { _ in })
        for _ in 0..<treeCount {
            store.addMarker(at: CLLocationCoordinate2D(latitude: 1, longitude: 1), note: "")
        }
        return store
    }

    func testInitialLevelForNewUser() {
        let store = makeStore(treeCount: 0)
        let viewModel = ProfileViewModel(treeStore: store)

        XCTAssertEqual(viewModel.level, 1)
        XCTAssertEqual(viewModel.progressToNextLevel, 0)
        XCTAssertEqual(viewModel.unlockedAchievements().count, 0)
    }

    func testLevelProgressionAndAchievements() {
        let store = makeStore(treeCount: 30)
        let viewModel = ProfileViewModel(treeStore: store)

        XCTAssertEqual(viewModel.level, 3)
        XCTAssertGreaterThan(viewModel.progressToNextLevel, 0)
        XCTAssertEqual(viewModel.unlockedAchievements().count, 3)
        XCTAssertEqual(viewModel.lockedAchievements().count, viewModel.achievements.count - 3)
    }

    func testRecalculateRespondsToTreeGrowth() {
        let store = makeStore(treeCount: 9)
        let viewModel = ProfileViewModel(treeStore: store)

        XCTAssertEqual(viewModel.level, 1)

        store.addMarker(at: CLLocationCoordinate2D(latitude: 2, longitude: 2), note: "")
        viewModel.recalculate()

        XCTAssertEqual(viewModel.level, 2)
    }
}
