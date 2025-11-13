import Foundation
import MapKit
import SwiftUI
import Combine

@MainActor
final class DiscoveryViewModel: ObservableObject {
    @Published var showAddNoteSheet = false
    @Published var pendingCoordinate: CLLocationCoordinate2D?
    @Published var noteText: String = ""
    @Published var isMapExpanded: Bool = true
    @Published private(set) var cameraPosition: MapCameraPosition
    @Published private(set) var markers: [TreeMarker] = []

    private let treeStore: TreeStore
    private let locationProvider: LocationProviding
    private let coverageRadius: CLLocationDistance = 100
    private var cancellables = Set<AnyCancellable>()

    init(treeStore: TreeStore, locationProvider: LocationProviding) {
        self.treeStore = treeStore
        self.locationProvider = locationProvider
        self.cameraPosition = .region(treeStore.mapRegion)
        markers = treeStore.markers
        treeStore.$markers
            .receive(on: RunLoop.main)
            .sink { [weak self] newMarkers in
                self?.markers = newMarkers
            }
            .store(in: &cancellables)
    }

    var totalTrees: Int {
        markers.count
    }

    func focusOnUser() {
        guard let coordinate = locationProvider.lastLocation?.coordinate else { return }
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        treeStore.mapRegion = region
        cameraPosition = .region(region)
    }

    func prepareMarkerCreation(at coordinate: CLLocationCoordinate2D) {
        pendingCoordinate = coordinate
        noteText = ""
        showAddNoteSheet = true
    }

    func addMarker() {
        guard let coordinate = pendingCoordinate else { return }
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        treeStore.addMarker(at: coordinate, note: trimmed)
        showAddNoteSheet = false
        pendingCoordinate = nil
        noteText = ""
    }

    func removeMarker(_ marker: TreeMarker) {
        treeStore.removeMarker(marker)
    }

    var currentMapCenter: CLLocationCoordinate2D {
        treeStore.mapRegion.center
    }

    func setCameraPosition(_ position: MapCameraPosition) {
        cameraPosition = position
    }

    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        treeStore.mapRegion = region
    }
}
