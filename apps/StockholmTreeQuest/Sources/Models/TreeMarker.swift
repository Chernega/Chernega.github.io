import Foundation
import MapKit

struct TreeMarker: Identifiable, Codable, Hashable {
    let id: UUID
    var latitude: Double
    var longitude: Double
    var note: String
    var createdAt: Date

    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D, note: String, createdAt: Date = Date()) {
        self.id = id
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.note = note
        self.createdAt = createdAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
