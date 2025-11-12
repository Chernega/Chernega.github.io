import GameKit

extension Friend {
    init(gameCenterPlayer player: GKPlayer) {
        let emoji = Friend.makeEmoji(from: player)
        let teamPlayerID = player.teamPlayerID
        let identifier = teamPlayerID.isEmpty ? player.gamePlayerID : teamPlayerID
        self.init(
            id: identifier,
            displayName: player.displayName,
            avatar: emoji,
            totalTrees: 0,
            city: "",
            visits: [],
            lastActive: Date()
        )
    }

    private static func makeEmoji(from player: GKPlayer) -> String {
        let symbols = ["🌲", "🎄", "❄️", "🦌", "🧚‍♀️", "🧝‍♂️", "🧙‍♂️", "🦉", "🪵", "🌌"]
        let hash = abs(player.displayName.hashValue)
        return symbols[hash % symbols.count]
    }
}
