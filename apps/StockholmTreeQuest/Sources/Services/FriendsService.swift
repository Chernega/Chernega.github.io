import Foundation
import GameKit

@MainActor
final class FriendsService: ObservableObject {
    @Published private(set) var friends: [Friend] = []
    @Published private(set) var isAuthenticated: Bool
    @Published var isLoading: Bool = false
    @Published var lastError: String?

    private let authenticationProvider: () -> Bool
    private let loader: () async throws -> [Friend]

    init(
        authenticationProvider: @escaping () -> Bool = { GKLocalPlayer.local.isAuthenticated },
        loader: @escaping () async throws -> [Friend] = FriendsService.loadFromGameCenter
    ) {
        self.authenticationProvider = authenticationProvider
        self.loader = loader
        self.isAuthenticated = authenticationProvider()
    }

    func refresh() async {
        guard authenticationProvider() else {
            isAuthenticated = false
            friends = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            friends = try await loader()
            isAuthenticated = true
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            friends = []
        }
    }

    func friend(for id: Friend.ID) -> Friend? {
        friends.first { $0.id == id }
    }

    func clear() {
        friends = []
    }

    private static func loadFromGameCenter() async throws -> [Friend] {
        try await withCheckedThrowingContinuation { continuation in
            GKLocalPlayer.local.loadFriends { players, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let friends = (players ?? []).map { Friend(gameCenterPlayer: $0) }
                    continuation.resume(returning: friends)
                }
            }
        }
    }
}
