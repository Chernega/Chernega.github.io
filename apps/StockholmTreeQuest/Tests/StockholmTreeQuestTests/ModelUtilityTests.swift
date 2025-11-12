import XCTest
import CoreLocation
@testable import StockholmTreeQuest

final class ModelUtilityTests: XCTestCase {
    func testAchievementUnlocking() {
        let achievement = Achievement(id: "test", titleKey: "test.title", subtitleKey: "test.subtitle", icon: "", threshold: 5)
        XCTAssertFalse(achievement.isUnlocked(totalTrees: 4))
        XCTAssertTrue(achievement.isUnlocked(totalTrees: 5))
    }

    func testTreeMarkerCoordinateRoundTrip() {
        let coordinate = CLLocationCoordinate2D(latitude: 12.3, longitude: 45.6)
        let marker = TreeMarker(coordinate: coordinate, note: "Test")
        XCTAssertEqual(marker.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(marker.coordinate.longitude, coordinate.longitude)
    }

    func testFriendVisitCoordinateRoundTrip() {
        let coordinate = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.21)
        let visit = Friend.TreeVisit(coordinate: coordinate)
        XCTAssertEqual(visit.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(visit.coordinate.longitude, coordinate.longitude)
    }

    func testAppLanguageDisplayNames() {
        XCTAssertEqual(AppLanguage.english.displayName, "English")
        XCTAssertEqual(AppLanguage.spanish.displayName, "Español")
    }
}
