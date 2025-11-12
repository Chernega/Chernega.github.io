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

    let id: String
    var displayName: String
    var avatar: String
    var totalTrees: Int
    var city: String
    var visits: [TreeVisit]
    var lastActive: Date

    init(
        id: String = UUID().uuidString,
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

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case avatar
        case totalTrees
        case city
        case visits
        case lastActive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else if let uuidID = try? container.decode(UUID.self, forKey: .id) {
            id = uuidID.uuidString
        } else {
            id = UUID().uuidString
        }
        displayName = try container.decode(String.self, forKey: .displayName)
        avatar = try container.decode(String.self, forKey: .avatar)
        totalTrees = try container.decode(Int.self, forKey: .totalTrees)
        city = try container.decode(String.self, forKey: .city)
        visits = try container.decode([TreeVisit].self, forKey: .visits)
        lastActive = try container.decode(Date.self, forKey: .lastActive)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(avatar, forKey: .avatar)
        try container.encode(totalTrees, forKey: .totalTrees)
        try container.encode(city, forKey: .city)
        try container.encode(visits, forKey: .visits)
        try container.encode(lastActive, forKey: .lastActive)
    }
}
