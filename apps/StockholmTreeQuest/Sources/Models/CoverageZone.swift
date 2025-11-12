import MapKit

struct CoverageZone: Identifiable, Hashable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance

    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.id = id
        self.coordinate = coordinate
        self.radius = radius
    }

    static func == (lhs: CoverageZone, rhs: CoverageZone) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum CoverageZoneBuilder {
    static func zones(
        for coordinates: [CLLocationCoordinate2D],
        radius: CLLocationDistance,
        mergeDistance: CLLocationDistance? = nil
    ) -> [CoverageZone] {
        let threshold = mergeDistance ?? radius * 0.6
        var zones: [CoverageZone] = []

        for coordinate in coordinates {
            if let index = zones.firstIndex(where: { $0.coordinate.distance(to: coordinate) <= threshold }) {
                let existing = zones[index]
                let averaged = existing.coordinate.midpoint(with: coordinate)
                zones[index] = CoverageZone(id: existing.id, coordinate: averaged, radius: radius)
            } else {
                zones.append(CoverageZone(coordinate: coordinate, radius: radius))
            }
        }

        return zones
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let current = CLLocation(latitude: latitude, longitude: longitude)
        let target = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return current.distance(from: target)
    }

    func midpoint(with other: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (latitude + other.latitude) / 2,
            longitude: (longitude + other.longitude) / 2
        )
    }
}
