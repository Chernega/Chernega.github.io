import XCTest
import MapKit
@testable import StockholmTreeQuest

final class TreeStoreTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        temporaryDirectory = nil
        try super.tearDownWithError()
    }

    func testAddMarkerPlacesNewestAtBeginning() {
        let store = TreeStore(
            baseDirectory: temporaryDirectory,
            persistHandler: { _ in }
        )

        store.addMarker(at: CLLocationCoordinate2D(latitude: 1, longitude: 1), note: "First")
        store.addMarker(at: CLLocationCoordinate2D(latitude: 2, longitude: 2), note: "Second")

        XCTAssertEqual(store.markers.count, 2)
        XCTAssertEqual(store.markers.first?.note, "Second")
    }

    func testPersistAndLoadRoundTripsMarkersSortedByCreationDate() async throws {
        let fileName = "tree_store.json"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        var first = TreeMarker(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), note: "Old")
        first.createdAt = Date(timeIntervalSince1970: 10)
        var second = TreeMarker(coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2), note: "New")
        second.createdAt = Date(timeIntervalSince1970: 20)

        let existing = [first, second]
        let directory = temporaryDirectory ?? FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent(fileName)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(existing)
        try data.write(to: url)

        let store = TreeStore(
            baseDirectory: directory,
            fileName: fileName,
            persistHandler: { _ in }
        )

        await store.load()

        XCTAssertEqual(store.markers.count, 2)
        XCTAssertEqual(store.markers.first?.note, "New")
        XCTAssertEqual(store.markers.last?.note, "Old")
    }

    func testPersistWritesFileToDisk() async throws {
        let fileName = "persist_test.json"
        let directory = temporaryDirectory ?? FileManager.default.temporaryDirectory
        let store = TreeStore(
            baseDirectory: directory,
            fileName: fileName,
            persistHandler: { action in Task { await action() } }
        )

        store.addMarker(at: CLLocationCoordinate2D(latitude: 3, longitude: 3), note: "Saved")
        await store.persist()

        let url = directory.appendingPathComponent(fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let data = try Data(contentsOf: url)
        XCTAssertFalse(data.isEmpty)
    }

    func testLoadHandlesMissingFileGracefully() async {
        let fileName = "missing.json"
        let directory = temporaryDirectory ?? FileManager.default.temporaryDirectory
        let store = TreeStore(
            baseDirectory: directory,
            fileName: fileName,
            persistHandler: { _ in }
        )

        await store.load()

        XCTAssertTrue(store.markers.isEmpty)
    }
}
