import Foundation
import MapKit

struct Friend: Identifiable, Hashable, Codable {
    struct TreeVisit: Identifiable, Hashable, Codable {
        let id: UUID
        var latitude: Double
        var longitude: Double
        var createdAt: Date

        init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D, createdAt: Date = Date()) {
            self.id = id
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.createdAt = createdAt
        }

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    let id: UUID
    var displayName: String
    var avatar: String
    var totalTrees: Int
    var city: String
    var visits: [TreeVisit]
    var lastActive: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        avatar: String,
        totalTrees: Int,
        city: String,
        visits: [TreeVisit],
        lastActive: Date
    ) {
        self.id = id
        self.displayName = displayName
        self.avatar = avatar
        self.totalTrees = totalTrees
        self.city = city
        self.visits = visits
        self.lastActive = lastActive
    }
}
