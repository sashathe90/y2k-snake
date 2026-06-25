
import Foundation

enum LeaderboardManager {
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
        return decoded
    }
    
    static func save(_ list: [ScoreEntry], for mode: GameMode, speed: Int?) {
        let key = key(for: mode, speed: speed)
        if let data = try? JSONEncoder().encode(list) {
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
