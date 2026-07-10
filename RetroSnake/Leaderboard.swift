
import Foundation

enum LeaderboardManager {
    private static func normalized(_ list: [ScoreEntry]) -> [ScoreEntry] {
        var seenEntries = Set<String>()

        return list
            .sorted { $0.score > $1.score }
            .filter { entry in
                let key = "\(entry.playerName.uppercased())|\(entry.score)"
                guard !seenEntries.contains(key) else { return false }
                seenEntries.insert(key)
                return true
            }
    }

    static func key(for mode: GameMode, speed: Int?) -> String {
        switch mode {
        case .classic:
            return "SnakeLeaderboard_classic_speed_\(speed ?? 1)"
        case .labyrinth:
            return "SnakeLeaderboard_maze_speed_\(speed ?? 1)"
        case .deathRace:
            return "SnakeLeaderboard_deathRace"
        case .speedRun:
            return "SnakeLeaderboard_speedRun"
        }
    }
    
    static func load(for mode: GameMode, speed: Int?) -> [ScoreEntry] {
        let key = key(for: mode, speed: speed)
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ScoreEntry].self, from: data) else {
            return []
        }
        return Array(normalized(decoded).prefix(5))
    }
    
    static func save(_ list: [ScoreEntry], for mode: GameMode, speed: Int?) {
        let key = key(for: mode, speed: speed)
        let normalizedList = Array(normalized(list).prefix(5))
        if let data = try? JSONEncoder().encode(normalizedList) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    static func removeScores(for playerName: String) {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        
        for key in keys where key.hasPrefix("SnakeLeaderboard_") {
            guard let data = defaults.data(forKey: key),
                  let scores = try? JSONDecoder().decode([ScoreEntry].self, from: data) else {
                continue
            }
            
            let filteredScores = scores.filter { $0.playerName != playerName }
            
            if filteredScores.isEmpty {
                defaults.removeObject(forKey: key)
            } else if let encodedData = try? JSONEncoder().encode(filteredScores) {
                defaults.set(encodedData, forKey: key)
            }
        }
    }
    
    static func resetAll() {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys
        
        for key in keys where key.hasPrefix("SnakeLeaderboard_") {
            defaults.removeObject(forKey: key)
        }
    }
}
