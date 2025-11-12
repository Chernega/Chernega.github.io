import XCTest
import CoreLocation
import MapKit
@testable import StockholmTreeQuest

@MainActor
final class DiscoveryViewModelTests: XCTestCase {
    private final class MockLocationProvider: LocationProviding {
        var lastLocation: CLLocation?
    }

    func testPrepareMarkerShowsSheetAndResetsNote() {
        let store = TreeStore(persistHandler: { _ in })
        let location = MockLocationProvider()
        let viewModel = DiscoveryViewModel(treeStore: store, locationProvider: location)

        let coordinate = CLLocationCoordinate2D(latitude: 10, longitude: 10)
        viewModel.noteText = "Existing"
        viewModel.prepareMarkerCreation(at: coordinate)

        XCTAssertTrue(viewModel.showAddNoteSheet)
        XCTAssertEqual(viewModel.pendingCoordinate?.latitude, coordinate.latitude)
        XCTAssertEqual(viewModel.noteText, "")
    }

    func testAddMarkerTrimsNoteAndClearsState() {
        let store = TreeStore(persistHandler: { _ in })
        let location = MockLocationProvider()
        let viewModel = DiscoveryViewModel(treeStore: store, locationProvider: location)

        let coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        viewModel.prepareMarkerCreation(at: coordinate)
        viewModel.noteText = "  Snowy tree  "
        viewModel.addMarker()

        XCTAssertEqual(store.markers.count, 1)
        XCTAssertEqual(store.markers.first?.note, "Snowy tree")
        XCTAssertNil(viewModel.pendingCoordinate)
        XCTAssertFalse(viewModel.showAddNoteSheet)
        XCTAssertEqual(viewModel.noteText, "")
    }

    func testFocusOnUserUpdatesCameraRegion() {
        let store = TreeStore(persistHandler: { _ in })
        let location = MockLocationProvider()
        location.lastLocation = CLLocation(latitude: 59.3, longitude: 18.0)
        let viewModel = DiscoveryViewModel(treeStore: store, locationProvider: location)

        viewModel.focusOnUser()

        XCTAssertEqual(store.mapRegion.center.latitude, 59.3, accuracy: 0.0001)
        XCTAssertEqual(store.mapRegion.center.longitude, 18.0, accuracy: 0.0001)
        XCTAssertEqual(store.mapRegion.span.latitudeDelta, 0.01, accuracy: 0.0001)
        XCTAssertEqual(store.mapRegion.span.longitudeDelta, 0.01, accuracy: 0.0001)
    }
}
