import Foundation
import MapKit

@MainActor
final class TreeStore: ObservableObject {
    @Published private(set) var markers: [TreeMarker] = []
    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    private let persistenceURL: URL
    private let fileManager: FileManager
    private let persistHandler: (@escaping () async -> Void) -> Void
    private let ioQueue = DispatchQueue(label: "com.chernega.treestore.io", qos: .utility)

    init(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil,
        fileName: String = "tree_markers.json",
        persistHandler: @escaping (@escaping () async -> Void) -> Void = { action in
            Task { await action() }
        }
    ) {
        self.fileManager = fileManager
        self.persistHandler = persistHandler
        let directory = baseDirectory
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        persistenceURL = directory.appendingPathComponent(fileName)
    }

    func load() async {
        do {
            let decoded = try await readMarkersFromDisk()
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
            try await writeMarkersToDisk(snapshot)
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

    private func readMarkersFromDisk() async throws -> [TreeMarker] {
        let url = persistenceURL
        let fileManager = fileManager
        return try await withCheckedThrowingContinuation { continuation in
            ioQueue.async {
                do {
                    guard fileManager.fileExists(atPath: url.path) else {
                        continuation.resume(returning: [])
                        return
                    }
                    let data = try Data(contentsOf: url)
                    let decoder = Self.makeDecoder()
                    let decoded = try decoder.decode([TreeMarker].self, from: data)
                    continuation.resume(returning: decoded)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func writeMarkersToDisk(_ markers: [TreeMarker]) async throws {
        let url = persistenceURL
        let fileManager = fileManager
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ioQueue.async {
                do {
                    let directory = url.deletingLastPathComponent()
                    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                    let encoder = Self.makeEncoder()
                    let data = try encoder.encode(markers)
                    try data.write(to: url, options: .atomic)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
