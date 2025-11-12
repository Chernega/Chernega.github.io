import Foundation
import MapKit
import SwiftUI

@MainActor
final class DiscoveryViewModel: ObservableObject {
    @Published var showAddNoteSheet = false
    @Published var pendingCoordinate: CLLocationCoordinate2D?
    @Published var noteText: String = ""
    @Published var isMapExpanded: Bool = true

    private let treeStore: TreeStore
    private let locationProvider: LocationProviding

    init(treeStore: TreeStore, locationProvider: LocationProviding) {
        self.treeStore = treeStore
        self.locationProvider = locationProvider
    }

    var markers: [TreeMarker] {
        treeStore.markers
    }

    var totalTrees: Int {
        treeStore.totalTreesDiscovered
    }

    var currentRegion: Binding<MKCoordinateRegion> {
        Binding(
            get: { self.treeStore.mapRegion },
            set: { self.treeStore.mapRegion = $0 }
        )
    }

    func focusOnUser() {
        guard let coordinate = locationProvider.lastLocation?.coordinate else { return }
        treeStore.mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
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
}
