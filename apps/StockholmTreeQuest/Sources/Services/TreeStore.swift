import Foundation
import MapKit

@MainActor
final class TreeStore: ObservableObject {
    @Published private(set) var markers: [TreeMarker] = []
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private let persistenceURL: URL
    private let persistHandler: @Sendable (@Sendable @escaping () async -> Void) -> Void
    private let persistenceActor: TreePersistenceActor

    init(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil,
        fileName: String = "tree_markers.json",
        persistHandler: @escaping @Sendable (@Sendable @escaping () async -> Void) -> Void = { action in
            Task { @MainActor in await action() }
        }
    ) {
        self.persistHandler = persistHandler
        let directory = baseDirectory
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        persistenceURL = directory.appendingPathComponent(fileName)
        persistenceActor = TreePersistenceActor()
    }

    func load() async {
        do {
            let decoded = try await persistenceActor.readMarkers(from: persistenceURL)
            markers = decoded.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            #if DEBUG
            print("No stored markers yet: \(error.localizedDescription)")
            #endif
            markers = []
        }
    }

    func persist() async {
        let snapshot = markers
        do {
            try await persistenceActor.writeMarkers(snapshot, to: persistenceURL)
        } catch {
            print("Failed to persist markers: \(error.localizedDescription)")
        }
    }

    func addMarker(at coordinate: CLLocationCoordinate2D, note: String) {
        let marker = TreeMarker(coordinate: coordinate, note: note)
        markers.insert(marker, at: 0)
        schedulePersist()
    }

    func removeMarker(_ marker: TreeMarker) {
        markers.removeAll { $0.id == marker.id }
        schedulePersist()
    }

    func removeAll() {
        markers.removeAll()
        schedulePersist()
    }

    var totalTreesDiscovered: Int {
        markers.count
    }

    private func schedulePersist() {
        persistHandler { [weak self] in
            guard let self else { return }
            await self.persist()
        }
    }
}

private actor TreePersistenceActor {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func readMarkers(from url: URL) throws -> [TreeMarker] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode([TreeMarker].self, from: data)
    }

    func writeMarkers(_ markers: [TreeMarker], to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(markers)
        try data.write(to: url, options: .atomic)
    }
}
