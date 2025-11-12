import Foundation

struct Achievement: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let subtitleKey: String
    let icon: String
    let threshold: Int

    func isUnlocked(totalTrees: Int) -> Bool {
        totalTrees >= threshold
    }
}
