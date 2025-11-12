import Foundation
import MapKit

@MainActor
final class FriendsService: ObservableObject {
    @Published private(set) var friends: [Friend] = []

    func load() async {
        // Simulate asynchronous loading with Task.sleep for realism while keeping launch snappy.
        try? await Task.sleep(nanoseconds: 150_000_000)
        friends = Self.sampleFriends()
    }

    func friend(for id: Friend.ID) -> Friend? {
        friends.first { $0.id == id }
    }

    private static func sampleFriends() -> [Friend] {
        let calendar = Calendar.current
        return [
            Friend(
                displayName: "Elena Frost",
                avatar: "🧝‍♀️",
                totalTrees: 42,
                city: "Reykjavík",
                visits: [
                    .init(coordinate: CLLocationCoordinate2D(latitude: 64.1265, longitude: -21.8174), createdAt: calendar.date(byAdding: .day, value: -3, to: Date())!),
                    .init(coordinate: CLLocationCoordinate2D(latitude: 64.1353, longitude: -21.8952), createdAt: calendar.date(byAdding: .day, value: -1, to: Date())!)
                ],
                lastActive: calendar.date(byAdding: .hour, value: -4, to: Date())!
            ),
            Friend(
                displayName: "Lucas Star",
                avatar: "🧙‍♂️",
                totalTrees: 58,
                city: "Stockholm",
                visits: [
                    .init(coordinate: CLLocationCoordinate2D(latitude: 59.3340, longitude: 18.0633), createdAt: calendar.date(byAdding: .day, value: -7, to: Date())!),
                    .init(coordinate: CLLocationCoordinate2D(latitude: 59.3250, longitude: 18.0717), createdAt: calendar.date(byAdding: .day, value: -2, to: Date())!)
                ],
                lastActive: calendar.date(byAdding: .hour, value: -11, to: Date())!
            ),
            Friend(
                displayName: "Maya Lights",
                avatar: "🧚‍♀️",
                totalTrees: 31,
                city: "Kyoto",
                visits: [
                    .init(coordinate: CLLocationCoordinate2D(latitude: 35.0116, longitude: 135.7681), createdAt: calendar.date(byAdding: .day, value: -5, to: Date())!),
                    .init(coordinate: CLLocationCoordinate2D(latitude: 35.0025, longitude: 135.7681), createdAt: calendar.date(byAdding: .day, value: -1, to: Date())!)
                ],
                lastActive: calendar.date(byAdding: .hour, value: -26, to: Date())!
            ),
            Friend(
                displayName: "Nate Evergreen",
                avatar: "🧑‍🚀",
                totalTrees: 64,
                city: "Vancouver",
                visits: [
                    .init(coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207), createdAt: calendar.date(byAdding: .day, value: -10, to: Date())!),
                    .init(coordinate: CLLocationCoordinate2D(latitude: 49.2609, longitude: -123.1139), createdAt: calendar.date(byAdding: .day, value: -2, to: Date())!)
                ],
                lastActive: calendar.date(byAdding: .hour, value: -36, to: Date())!
            )
        ]
    }
}
