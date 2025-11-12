import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var achievements: [Achievement] = []
    @Published private(set) var level: Int = 1
    @Published private(set) var progressToNextLevel: Double = 0
    @Published private(set) var statusTitle: String = ""

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
        statusTitle = Self.title(for: level)
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

    private static func title(for level: Int) -> String {
        switch level {
        case 1: return NSLocalizedString("profile.status.sprout", comment: "")
        case 2: return NSLocalizedString("profile.status.orb", comment: "")
        case 3: return NSLocalizedString("profile.status.comet", comment: "")
        case 4: return NSLocalizedString("profile.status.aurora", comment: "")
        default: return NSLocalizedString("profile.status.legend", comment: "")
        }
    }

    private static let defaultAchievements: [Achievement] = [
        Achievement(
            id: "first-tree",
            title: NSLocalizedString("achievement.first_tree.title", comment: ""),
            subtitle: NSLocalizedString("achievement.first_tree.subtitle", comment: ""),
            icon: "🎄",
            threshold: 1
        ),
        Achievement(
            id: "frost-trail",
            title: NSLocalizedString("achievement.frost_trail.title", comment: ""),
            subtitle: NSLocalizedString("achievement.frost_trail.subtitle", comment: ""),
            icon: "❄️",
            threshold: 10
        ),
        Achievement(
            id: "north-star",
            title: NSLocalizedString("achievement.north_star.title", comment: ""),
            subtitle: NSLocalizedString("achievement.north_star.subtitle", comment: ""),
            icon: "🌟",
            threshold: 25
        ),
        Achievement(
            id: "aurora-leader",
            title: NSLocalizedString("achievement.aurora_leader.title", comment: ""),
            subtitle: NSLocalizedString("achievement.aurora_leader.subtitle", comment: ""),
            icon: "🛷",
            threshold: 50
        ),
        Achievement(
            id: "legend",
            title: NSLocalizedString("achievement.legend.title", comment: ""),
            subtitle: NSLocalizedString("achievement.legend.subtitle", comment: ""),
            icon: "👑",
            threshold: 100
        )
    ]
}
