import Foundation

struct Point: Hashable {
    let x: Int
    let y: Int
}

enum Direction {
    case up, down, left, right
}

enum GameMode: String {
    case classic = "CLASSIC"
    case speedRun = "SPEED RUN"
    case deathRace = "DEATH RACE"
    case labyrinth = "MAZE"
}

enum ControlLayout: String, CaseIterable {
    case classic = "CLASSIC"
    case right = "RIGHT"
    case left = "LEFT"
}

enum SkinsReturnContext {
    case firstLaunchPlayerCreation
    case playerSelection
    case vsPlayerSelection
    case settings
    case vsSettings
}

enum SnakeSkin: String, CaseIterable, Hashable {
    case black
    case rainbow
    case white
    case red
    case yellow
    case blue

    var displayName: String {
        rawValue.uppercased()
    }

    var isLocked: Bool {
        // TODO: Before App Store paid release, restore rainbow lock and connect StoreKit non-consumable purchase.
        false
    }
}

enum AIDifficulty: String {
    case easy = "EASY"
    case normal = "NORMAL"
    case hard = "HARD"
}

enum GameScreen {
    case playerSelection
    case playerManagement
    case playerActions
    case newPlayer
    case deletePlayerConfirmation
    case playTypeSelection
    case startMenu
    case multiplayerMenu
    case multiplayerVSMainMenu
    case multiplayerVSModeSelection
    case multiplayerVSAIDifficultySelection
    case multiplayerVSScores
    case multiplayerVSScoresSpeedSelection
    case multiplayerVSScoresDifficultySelection
    case multiplayerVSScoresDetail
    case modeSelection
    case speedSelection
    case scoresMenu
    case settingsMenu
    case skinsMenu
    case soundMenu
    case credits
    case controlMenu
    case scoresSpeedSelection
    case scoresDetail
    case allSpeedScores
    case allScores
    case resetScoresConfirmation
    case restartGameConfirmation
    case returnToMenuConfirmation
    case playing
    case paused
    case gameOver
    case gameWon
    case timeUp
}

enum SuperFoodType: CaseIterable {
    case butterfly
    case bug
    case caterpillar
    case spider
    case scorpion
}

enum BonusItemType {
    case mysteryPill
}

enum PillEffect {
    case none
    case speed
    case invert
    case slow
    case rainbow
    case flicker
    case scoreBonus
    case scoreJackpot
}

struct ScoreEntry: Codable, Hashable {
    let playerName: String
    let score: Int
}
