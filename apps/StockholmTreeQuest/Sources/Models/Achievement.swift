import Foundation

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let threshold: Int

    func isUnlocked(totalTrees: Int) -> Bool {
        totalTrees >= threshold
    }
}
