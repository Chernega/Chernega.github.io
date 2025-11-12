import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var achievements: [Achievement] = []
    @Published private(set) var level: Int = 1
    @Published private(set) var progressToNextLevel: Double = 0
    @Published private(set) var statusKey: String = "profile.status.sprout"

    private let treeStore: TreeStore

    init(treeStore: TreeStore) {
        self.treeStore = treeStore
        achievements = Self.defaultAchievements
        recalculate()
    }

    func recalculate() {
        let total = treeStore.totalTreesDiscovered
        level = Self.level(for: total)
        let nextLevelRequirement = Self.threshold(for: level + 1)
        let currentLevelRequirement = Self.threshold(for: level)
        let progress = Double(total - currentLevelRequirement)
        let span = Double(max(nextLevelRequirement - currentLevelRequirement, 1))
        progressToNextLevel = min(max(progress / span, 0), 1)
        statusKey = Self.titleKey(for: level)
    }

    func unlockedAchievements() -> [Achievement] {
        achievements.filter { $0.isUnlocked(totalTrees: treeStore.totalTreesDiscovered) }
    }

    func lockedAchievements() -> [Achievement] {
        achievements.filter { !$0.isUnlocked(totalTrees: treeStore.totalTreesDiscovered) }
    }

    private static func level(for totalTrees: Int) -> Int {
        switch totalTrees {
        case 0..<10: return 1
        case 10..<25: return 2
        case 25..<50: return 3
        case 50..<100: return 4
        default: return 5
        }
    }

    private static func threshold(for level: Int) -> Int {
        switch level {
        case 1: return 0
        case 2: return 10
        case 3: return 25
        case 4: return 50
        default: return 100
        }
    }

    private static func titleKey(for level: Int) -> String {
        switch level {
        case 1: return "profile.status.sprout"
        case 2: return "profile.status.orb"
        case 3: return "profile.status.comet"
        case 4: return "profile.status.aurora"
        default: return "profile.status.legend"
        }
    }

    private static let defaultAchievements: [Achievement] = [
        Achievement(
            id: "first-tree",
            titleKey: "achievement.first_tree.title",
            subtitleKey: "achievement.first_tree.subtitle",
            icon: "🎄",
            threshold: 1
        ),
        Achievement(
            id: "frost-trail",
            titleKey: "achievement.frost_trail.title",
            subtitleKey: "achievement.frost_trail.subtitle",
            icon: "❄️",
            threshold: 10
        ),
        Achievement(
            id: "north-star",
            titleKey: "achievement.north_star.title",
            subtitleKey: "achievement.north_star.subtitle",
            icon: "🌟",
            threshold: 25
        ),
        Achievement(
            id: "aurora-leader",
            titleKey: "achievement.aurora_leader.title",
            subtitleKey: "achievement.aurora_leader.subtitle",
            icon: "🛷",
            threshold: 50
        ),
        Achievement(
            id: "legend",
            titleKey: "achievement.legend.title",
            subtitleKey: "achievement.legend.subtitle",
            icon: "👑",
            threshold: 100
        )
    ]
}
