import SwiftUI
import UIKit

struct ContentView: View {
    static func snakeSkinStorageKey(for playerName: String) -> String {
        "Y2KSnakeSelectedSkin_\(playerName.uppercased())"
    }

    static func loadSnakeSkin(for playerName: String) -> SnakeSkin {
        guard !playerName.isEmpty else { return .black }
        let savedValue = UserDefaults.standard.string(forKey: snakeSkinStorageKey(for: playerName)) ?? ""
        guard let savedSkin = SnakeSkin(rawValue: savedValue), !savedSkin.isLocked else {
            return .black
        }
        return savedSkin
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var snake: [Point] = [
        Point(x: 10, y: 16),
        Point(x: 9, y: 16),
        Point(x: 8, y: 16),
        Point(x: 7, y: 16)
    ]
    @State private var food = Point(x: 20, y: 16)
    @State private var direction: Direction = .right
    @State private var nextDirection: Direction = .right
    @State private var queuedDirections: [Direction] = []
    @State private var protectNextMoveAfterRespawn = false
    @State private var gameSessionID = UUID()
    @State private var score = 0
    @State private var highScore = UserDefaults.standard.integer(forKey: "HighScore")
    @State private var lives = 3
    @State private var level = 1
    @State private var speedRunFoodCount = 0
    @State private var selectedMode: GameMode = .classic
    @State private var selectedSpeed = 3
    @State private var selectedScoresMode: GameMode = .classic
    @State private var selectedScoresSpeed = 3
    @State private var selectedVSScoresSpeed = 3
    @State private var selectedVSScoresDifficulty: AIDifficulty = .normal
    @State private var selectedVSAIDifficulty: AIDifficulty = .normal
    @State private var selectedControlLayout: ControlLayout = ControlLayout(rawValue: UserDefaults.standard.string(forKey: "SnakeControlLayout") ?? "CLASSIC") ?? .classic
    @State private var selectedSnakeSkin: SnakeSkin = {
        let savedPlayer = UserDefaults.standard.string(forKey: "CurrentSnakePlayer") ?? ""
        return ContentView.loadSnakeSkin(for: savedPlayer)
    }()
    @State private var screen: GameScreen = {
        let savedPlayer = UserDefaults.standard.string(forKey: "CurrentSnakePlayer") ?? ""
        return savedPlayer.isEmpty ? .playerSelection : .playTypeSelection
    }()
    @State private var soundEnabled = UserDefaults.standard.object(forKey: "Y2KSnakeSoundEnabled") as? Bool ?? true
    @State private var hapticsEnabled = UserDefaults.standard.object(forKey: "Y2KSnakeHapticsEnabled") as? Bool ?? true
    @State private var controlHapticGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var players: [String] = UserDefaults.standard.stringArray(forKey: "SnakePlayers") ?? []
    @State private var currentPlayerName = UserDefaults.standard.string(forKey: "CurrentSnakePlayer") ?? ""
    @State private var newPlayerName = ""
    @FocusState private var isNewPlayerNameFocused: Bool
    @State private var selectedPlayerForAction: String? = nil
    @State private var playerToDelete: String? = nil
    @State private var shouldReturnToPlayerManagementAfterNewPlayer = false
    @State private var shouldReturnToStartAfterPlayerManagement = false
    @State private var shouldReturnToVSAfterPlayerManagement = false
    @State private var shouldReturnToVSAfterSettings = false
    @State private var shouldReturnToVSAfterAllScores = false
    @State private var skinsReturnContext: SkinsReturnContext = .settings
    @State private var shouldReturnToPauseAfterControl = false
    @State private var shouldReturnToPauseAfterSound = false
    @State private var shouldReturnToPauseAfterScores = false
    @State private var newRecordAchieved = false
    @State private var canMove = false
    @State private var lastMoveTime = Date()
    @State private var snakeVisible = true
    @State private var isRespawning = false
    @State private var countdownText: String? = nil
    @State private var countdownToken = 0
    @State private var countdownEndTime: Date? = nil
    @State private var pausedCountdownRemainingTime: TimeInterval? = nil
    @State private var pausedTimedRunRemainingTime: TimeInterval? = nil
    @State private var bonusOverlayText: String? = nil
    @State private var pillPickupCount = 0
    @State private var shouldUsePillTutorialThisGame = false
    @State private var lastPillEffect: PillEffect = .none
    @State private var legendMessageText: String? = nil
    @State private var jackpotOverlayKind: String? = nil
    @State private var digestionBumps: [Point: Int] = [:]
    @State private var timedRunStartTime = Date()
    @State private var timedRunSecondsLeft = 60
    @State private var lastFinalCountdownTickSecond = -1
    @State private var isMultiplayerVSMatch = false
    @State private var aiSnake: [Point] = []
    @State private var aiDirection: Direction = .up
    @State private var aiNextDirection: Direction = .up
    @State private var aiScore = 0
    @State private var aiLives = 3
    @State private var multiplayerVSTimeLeft = 300
    @State private var multiplayerVSStartTime = Date()
    @State private var pausedMultiplayerVSRemainingTime: TimeInterval? = nil
    @State private var multiplayerVSResult: MultiplayerVSResult = .draw
    @State private var multiplayerPlayerVisible = true
    @State private var multiplayerAIVisible = true
    @State private var aiFoodReactionMovesRemaining = 0
    @State private var aiTargetFood: Point? = nil
    @State private var aiDangerReactionMovesRemaining = 0
    @State private var aiDangerAheadLastTick = false
    @State private var didPlayBootSound = false
    @State private var superFood: Point? = nil
    @State private var superFoodSpawnTime = Date()
    @State private var superFoodVisible = false
    @State private var superFoodBlinkFrame = 0
    @State private var superFoodType: SuperFoodType = .butterfly
    @State private var lastSuperFoodType: SuperFoodType? = nil
    @State private var pausedSuperFoodRemainingTime: TimeInterval? = nil
    @State private var pausedMazeFoodRemainingTime: TimeInterval? = nil
    @State private var speedPill: Point? = nil
    @State private var speedPillVisible = false
    @State private var speedPillSpawnTime = Date()
    @State private var speedPillBlinkFrame = 0
    @State private var pausedSpeedPillRemainingTime: TimeInterval? = nil
    @State private var speedPillActive = false
    @State private var speedPillEndTime = Date()
    @State private var speedPillSecondsLeft = 0
    @State private var activePillEffect: PillEffect = .none
    @State private var pausedPillEffectRemainingTime: TimeInterval? = nil
    @State private var pillEffectBag: [PillEffect] = []
    @State private var speedPillPulseScale: CGFloat = 1.0
    @State private var speedPillFlickerOpacity: Double = 1.0
    @State private var walls: Set<Point> = []

    let columns = 32
    let rows = 32
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var lcdColor: Color {
        Color(red: 0.58, green: 0.64, blue: 0.43)
    }

    var effectiveSpeed: Int {
        switch selectedMode {
        case .classic, .labyrinth:
            return selectedSpeed
        case .deathRace:
            return level
        case .speedRun:
            return 5
        }
    }

    var gameSpeed: Double {
        switch activePillEffect {
        case .speed:
            return 0.048
        case .slow:
            return 0.55
        case .none, .invert, .rainbow, .flicker, .scoreBonus, .scoreJackpot:
            break
        }

        switch selectedMode {
        case .classic, .labyrinth:
            return max(0.07, 0.36 - Double(effectiveSpeed) * 0.055)
        case .deathRace:
            return max(0.055, 0.42 - Double(min(level, 6)) * 0.065)
        case .speedRun:
            return 0.048
        }
    }

    var superFoodDuration: Double {
        if selectedMode == .speedRun {
            return 2.5
        }

        switch effectiveSpeed {
        case 1: return 9
        case 2: return 8
        case 3: return 7
        case 4: return 5
        default: return 4
        }
    }

    var speedPillDuration: Double {
        if selectedMode == .speedRun {
            return 3.5
        }

        switch effectiveSpeed {
        case 1: return 9
        case 2: return 8
        case 3: return 7
        case 4: return 5
        default: return 4
        }
    }

    var postLevelUpPauseDuration: Double {
        1.0
    }

    var boardFrameThickness: CGFloat {
        2
    }

    var landscapeControlsOutwardOffset: CGFloat {
        16
    }

    func isCompactPortrait(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width <= 390 || geometry.size.height <= 760
    }

    func isIPadScreen(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width >= 700 || geometry.size.height >= 1000
    }

    func usesExpandedMenuLayout(_ geometry: GeometryProxy) -> Bool {
        min(geometry.size.width, geometry.size.height) >= 540
    }

    func landscapeControlsWidth(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 830 ? 142 : 150
    }

    func landscapeControlsSpacing(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 830 ? 20 : 24
    }

    func landscapeControlsOffset(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 830 ? 10 : landscapeControlsOutwardOffset
    }

    func landscapeControlsScale(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 830 ? 0.94 : 1.0
    }

    var shouldShowGameTitleBadge: Bool {
        true
    }

    var isFirstLaunchOnboardingScreen: Bool {
        switch screen {
        case .playerSelection:
            return players.isEmpty && currentPlayerName.isEmpty
        case .newPlayer:
            return currentPlayerName.isEmpty
        case .skinsMenu, .onboardingControl:
            return skinsReturnContext == .firstLaunchPlayerCreation
        default:
            return false
        }
    }

    var shouldResumeMenuMusicOnActive: Bool {
        guard !isFirstLaunchOnboardingScreen else { return false }

        switch screen {
        case .playTypeSelection,
             .playing,
             .paused,
             .gameOver,
             .gameWon,
             .timeUp,
             .multiplayerVSResult,
             .restartGameConfirmation,
             .returnToMenuConfirmation:
            return false
        default:
            return true
        }
    }

    var isMultiplayerVSHUDVisible: Bool {
        isMultiplayerVSMatch || screen == .multiplayerVSResult
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height

                if isLandscape {
                    landscapeLayout(geometry: geometry)
                } else {
                    portraitLayout(geometry: geometry)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(timer) { _ in
            guard screen == .playing else { return }
            guard canMove else { return }
            guard !isRespawning else { return }

            let now = Date()
            if now.timeIntervalSince(lastMoveTime) >= gameSpeed {
                if isMultiplayerVSMatch {
                    moveMultiplayerVSMatch()
                } else {
                    moveSnake()
                }
                lastMoveTime = now
            }

            if isMultiplayerVSMatch {
                updateMultiplayerVSTimer()
            } else {
                updateSuperFood()
                updateSpeedPill()
                updateMazeFood()
                updateTimedSpeedRun()
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = false
            prewarmHaptics()
            _ = SoundManager.shared
            playInitialBootSoundIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            UIApplication.shared.isIdleTimerDisabled = false
            if newPhase == .active {
                SoundManager.shared.refreshAudioSessionIfNeeded()
                if shouldResumeMenuMusicOnActive {
                    SoundManager.shared.resumeAudioForAppLifecycle()
                }
            } else {
                pauseGameForAppLifecycle()
            }
        }
    }

    func portraitLayout(geometry: GeometryProxy) -> some View {
        let contentWidth = min(geometry.size.width - 40, 620)
        let compact = isCompactPortrait(geometry)
        let screenHeight = min(geometry.size.height * (compact ? 0.55 : 0.58), contentWidth * 1.18)
        let topOffset = geometry.size.height * 0.06
        let showsControlPreview = screen == .controlMenu
        let showsOnboardingControlPreview = screen == .onboardingControl
        let showsPortraitControls = screen == .playing || screen == .paused || showsControlPreview || showsOnboardingControlPreview
        let useCenteredIPadControls = isIPadScreen(geometry) && showsPortraitControls

        return ZStack(alignment: .top) {
            VStack(spacing: compact ? 10 : 12) {
                nokiaScreenWithEffects(isLandscape: false)
                    .frame(width: contentWidth, height: screenHeight)
                    .layoutPriority(1)

                if !useCenteredIPadControls, screen == .playing || screen == .paused {
                    pauseButton(isLandscape: false)
                }

                if !useCenteredIPadControls, showsPortraitControls {
                    controlPad
                        .frame(width: contentWidth, alignment: .center)
                        .scaleEffect(compact ? 0.86 : 0.92)
                        .padding(.bottom, compact ? 18 : 28)
                }
            }
            .frame(width: contentWidth, alignment: .top)
            .padding(.top, topOffset)

            if useCenteredIPadControls {
                let controlsTop = topOffset + screenHeight
                let controlsHeight = max(160, geometry.size.height - controlsTop)

                VStack(spacing: 18) {
                    if screen == .playing || screen == .paused {
                        pauseButton(isLandscape: false)
                    }

                    controlPad
                        .frame(width: contentWidth, alignment: .center)
                        .scaleEffect(0.92)
                }
                .frame(width: contentWidth, height: controlsHeight, alignment: .center)
                .position(x: geometry.size.width / 2, y: controlsTop + controlsHeight / 2)
            }

            if shouldShowGameTitleBadge {
                gameTitleBadge(isLandscape: false)
                    .padding(.top, max(6, topOffset * 0.24))
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
    }

    func landscapeScreenSize(for geometry: GeometryProxy) -> CGFloat {
        let controlsWidth = landscapeControlsWidth(for: geometry)
        let sideSpacing = landscapeControlsSpacing(for: geometry)
        let availableWidthWithControls = geometry.size.width - controlsWidth * 2 - sideSpacing * 2
        return min(geometry.size.height * 0.96, availableWidthWithControls)
    }

    @ViewBuilder
    func landscapeLayout(geometry: GeometryProxy) -> some View {
        let controlsWidth = landscapeControlsWidth(for: geometry)
        let sideSpacing = landscapeControlsSpacing(for: geometry)
        let controlsOffset = landscapeControlsOffset(for: geometry)
        let screenSize = landscapeScreenSize(for: geometry)
        let contentWidth = controlsWidth * 2 + screenSize + sideSpacing * 2
        let badgeX = (geometry.size.width - contentWidth) / 2 + controlsWidth / 2 - controlsOffset
        let badgeY = (geometry.size.height - screenSize) / 2 + 22

        ZStack {
            if screen == .playing || screen == .paused || screen == .controlMenu || screen == .onboardingControl {
                landscapePlayingLayout(geometry: geometry)
            } else {
                nokiaScreenWithEffects(isLandscape: true)
                    .frame(width: screenSize, height: screenSize)
                    .clipped()
            }

            gameTitleBadge(isLandscape: true)
                .frame(width: controlsWidth)
                .position(x: badgeX, y: badgeY)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }

    func landscapePlayingLayout(geometry: GeometryProxy) -> some View {
        let controlsWidth = landscapeControlsWidth(for: geometry)
        let sideSpacing = landscapeControlsSpacing(for: geometry)
        let controlsOffset = landscapeControlsOffset(for: geometry)
        let controlsScale = landscapeControlsScale(for: geometry)
        let screenSize = landscapeScreenSize(for: geometry)

        return HStack(spacing: sideSpacing) {
            leftLandscapeControls
                .frame(width: controlsWidth, height: screenSize, alignment: .center)
                .scaleEffect(controlsScale)
                .offset(x: -controlsOffset)

            nokiaScreenWithEffects(isLandscape: true)
                .frame(width: screenSize, height: screenSize)
                .clipped()

            ZStack(alignment: .bottom) {
                rightLandscapeControls
                    .frame(width: controlsWidth, height: screenSize, alignment: .center)

                if screen == .playing || screen == .paused {
                    pauseButton(isLandscape: true)
                }
            }
            .frame(width: controlsWidth, height: screenSize, alignment: .center)
            .scaleEffect(controlsScale)
            .offset(x: controlsOffset)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
    }

    func gameTitleBadge(isLandscape: Bool) -> some View {
        Text("Y2K SNAKE")
            .font(.system(size: isLandscape ? 22 : 28, weight: .black, design: .monospaced))
            .foregroundColor(lcdColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .allowsHitTesting(false)
    }

    var pillEffectHUDText: String {
        switch activePillEffect {
        case .none:
            return ""
        case .speed:
            return "P\(speedPillSecondsLeft)"
        case .invert:
            return "I\(speedPillSecondsLeft)"
        case .slow:
            return "S\(speedPillSecondsLeft)"
        case .rainbow:
            return "R\(speedPillSecondsLeft)"
        case .flicker:
            return "F\(speedPillSecondsLeft)"
        case .scoreBonus, .scoreJackpot:
            return ""
        }
    }

    var shouldInvertNokiaScreen: Bool {
        activePillEffect == .invert && screen == .playing && !isRespawning
    }

    var flickerOverlayOpacity: Double {
        guard activePillEffect == .flicker else { return 0 }
        guard screen == .playing && !isRespawning else { return 0 }

        let cycleDuration = 1.3
        let progress = Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
        let darkness = 0.5 - 0.5 * cos(progress * 2.0 * .pi)
        return min(1.0, max(0.0, darkness))
    }

    @ViewBuilder
    func nokiaScreenWithEffects(isLandscape: Bool = false) -> some View {
        ZStack {
            if shouldInvertNokiaScreen {
                nokiaScreen(isLandscape: isLandscape)
                    .colorInvert()
            } else {
                nokiaScreen(isLandscape: isLandscape)
            }

            if flickerOverlayOpacity > 0 {
                Color.black.opacity(flickerOverlayOpacity)
                    .animation(.easeInOut(duration: 0.08), value: flickerOverlayOpacity)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    func pillEffectHUD(size: CGFloat) -> some View {
        if activePillEffect == .rainbow {
            HStack(spacing: 0) {
                Text("R")
                    .font(.system(size: size, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange, .yellow, .blue, .purple, .pink],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                pixelText("\(speedPillSecondsLeft)", size: size)
            }
        } else {
            pixelText(pillEffectHUDText, size: size)
        }
    }

    func nokiaScreen(isLandscape: Bool = false) -> some View {
        let outerPadding: CGFloat = isLandscape ? 9 : 14
        let hudScoreSize: CGFloat = isLandscape ? 24 : 28
        let hudHiSize: CGFloat = isLandscape ? 19 : 22
        let hudHeartSize: CGFloat = isLandscape ? 22 : 26
        let hudModeSize: CGFloat = isLandscape ? 17 : 20
        let dividerBottomPadding: CGFloat = isLandscape ? 2 : 6
        let mainSpacing: CGFloat = isLandscape ? 5 : 8

        return VStack(spacing: mainSpacing) {
            ZStack {
                if isMultiplayerVSHUDVisible {
                    HStack {
                        pixelText("P \(score) ♥\(lives)", size: hudModeSize)
                            .frame(width: 130, alignment: .leading)

                        Spacer()

                        pixelText("AI \(aiScore) ♥\(aiLives)", size: hudModeSize)
                            .frame(width: 130, alignment: .trailing)
                    }

                    pixelText("\(multiplayerVSTimeLeft)", size: hudModeSize)
                } else {
                    HStack {
                        ZStack(alignment: .leading) {
                            pixelText(String(format: "%04d", score), size: hudScoreSize)

                            if activePillEffect != .none {
                                pillEffectHUD(size: isLandscape ? 14 : 17)
                                    .offset(x: 86, y: 2)
                            }
                        }
                        .frame(width: 130, alignment: .leading)

                        Spacer()

                        Group {
                            if screen == .playing || screen == .paused || screen == .gameOver || screen == .gameWon || screen == .timeUp {
                                switch selectedMode {
                                case .classic:
                                    pixelText("♥\(lives)", size: hudHeartSize)
                                case .speedRun:
                                    pixelText("RUN \(timedRunSecondsLeft) ♥\(lives)", size: hudModeSize)
                                case .deathRace:
                                    pixelText("DR L\(level) ♥\(lives)", size: hudModeSize)
                                case .labyrinth:
                                    pixelText("L\(level) ♥\(lives)", size: isLandscape ? 21 : 24)
                                }
                            } else {
                                pixelText("HI \(highScore)", size: hudHiSize)
                            }
                        }
                        .frame(width: 130, alignment: .trailing)
                    }
                }

                if screen == .playing, let bonusOverlayText {
                    pixelText(bonusOverlayText, size: isLandscape ? 12 : 14)
                        .offset(y: 2)
                }
            }

            Rectangle()
                .fill(Color.black.opacity(0.78))
                .frame(height: isLandscape ? 4 : 5)
                .padding(.bottom, dividerBottomPadding)

            GeometryReader { contentGeometry in
                let contentSize = min(contentGeometry.size.width, contentGeometry.size.height)

                ZStack {
                    squareBoard
                        .frame(width: contentSize, height: contentSize)

                    currentScreenOverlay(isLandscape: isLandscape)
                        .frame(width: contentSize, height: contentSize)

                    if screen == .playing, let countdownText {
                        pixelText(countdownText, size: countdownText == "GO" ? 44 : 54)
                    }
                    if screen == .playing, let legendMessageText {
                        legendMessageOverlay(text: legendMessageText)
                            .frame(width: contentSize, height: contentSize)
                    }

                    if screen == .playing, let jackpotOverlayKind {
                        jackpotOverlay(kind: jackpotOverlayKind)
                            .frame(width: contentSize, height: contentSize)
                    }
                }
                .frame(width: contentGeometry.size.width, height: contentGeometry.size.height, alignment: .center)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(outerPadding)
        .background(lcdColor)
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.78), lineWidth: 4)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func legendMessageOverlay(text: String) -> some View {
        ZStack {
            lcdColor.opacity(0.92)
            thinBoardBorder(thickness: boardFrameThickness)

            VStack(spacing: 8) {
                ForEach(text.components(separatedBy: "\n"), id: \.self) { line in
                    pixelText(line, size: line.contains("EXTRA") || line.contains("+10") ? 18 : 15)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
        }
    }

    func jackpotOverlay(kind: String) -> some View {
        ZStack {
            lcdColor.opacity(0.94)
            thinBoardBorder(thickness: boardFrameThickness)

            VStack(spacing: 12) {
                if kind == "time" {
                    pixelText("+20", size: 44)
                    largeStarIcon(size: 88)
                    pixelText("SECONDS", size: 30)
                } else if kind == "score" {
                    pixelText("+20", size: 44)
                    largeStarIcon(size: 88)
                    pixelText("SCORE", size: 30)
                } else {
                    pixelText("EXTRA", size: 34)
                    largeMedkitIcon(size: 92)
                    pixelText("LIFE", size: 38)
                }
            }
        }
    }

    func thinBoardBorder(thickness: CGFloat) -> some View {
        GeometryReader { geometry in
            thinBoardBorder(width: geometry.size.width, height: geometry.size.height, thickness: thickness)
        }
    }

    func thinBoardBorder(width: CGFloat, height: CGFloat, thickness: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.78))
                .frame(width: width, height: thickness)
                .position(x: width / 2, y: thickness / 2)

            Rectangle()
                .fill(Color.black.opacity(0.78))
                .frame(width: width, height: thickness)
                .position(x: width / 2, y: height - thickness / 2)

            Rectangle()
                .fill(Color.black.opacity(0.78))
                .frame(width: thickness, height: height)
                .position(x: thickness / 2, y: height / 2)

            Rectangle()
                .fill(Color.black.opacity(0.78))
                .frame(width: thickness, height: height)
                .position(x: width - thickness / 2, y: height / 2)
        }
        .frame(width: width, height: height)
    }

    func largeMedkitIcon(size: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.94))
                .frame(width: size, height: size)
                .overlay(
                    Rectangle()
                        .stroke(Color.black.opacity(0.78), lineWidth: max(3, size * 0.08))
                )

            Rectangle()
                .fill(Color.red)
                .frame(width: size * 0.22, height: size * 0.68)

            Rectangle()
                .fill(Color.red)
                .frame(width: size * 0.68, height: size * 0.22)
        }
    }

    func largeStarIcon(size: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow.opacity(0.95))
                .frame(width: size * 0.24, height: size)

            Rectangle()
                .fill(Color.yellow.opacity(0.95))
                .frame(width: size, height: size * 0.24)

            Rectangle()
                .fill(Color.yellow.opacity(0.95))
                .frame(width: size * 0.22, height: size * 0.82)
                .rotationEffect(.degrees(45))

            Rectangle()
                .fill(Color.yellow.opacity(0.95))
                .frame(width: size * 0.22, height: size * 0.82)
                .rotationEffect(.degrees(-45))

            Rectangle()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.18, height: size * 0.18)
        }
    }

    @ViewBuilder
    func currentScreenOverlay(isLandscape: Bool = false) -> some View {
        switch screen {
        case .playerSelection:
            playerSelectionOverlay
        case .playerManagement:
            playerManagementOverlay
        case .playerActions:
            playerActionsOverlay
        case .newPlayer:
            newPlayerOverlay
        case .deletePlayerConfirmation:
            deletePlayerOverlay
        case .playTypeSelection:
            playTypeSelectionOverlay(isLandscape: isLandscape)
        case .startMenu:
            startMenuOverlay(isLandscape: isLandscape)
        case .multiplayerMenu:
            multiplayerMenuOverlay(isLandscape: isLandscape)
        case .multiplayerVSMainMenu:
            multiplayerVSMainMenuOverlay(isLandscape: isLandscape)
        case .multiplayerVSModeSelection:
            multiplayerVSModeSelectionOverlay(isLandscape: isLandscape)
        case .multiplayerVSSpeedSelection:
            multiplayerVSSpeedSelectionOverlay(isLandscape: isLandscape)
        case .multiplayerVSAIDifficultySelection:
            multiplayerVSAIDifficultySelectionOverlay(isLandscape: isLandscape)
        case .multiplayerVSResult:
            multiplayerVSResultOverlay
        case .multiplayerVSScores:
            multiplayerVSScoresOverlay(isLandscape: isLandscape)
        case .multiplayerVSScoresSpeedSelection:
            multiplayerVSScoresSpeedSelectionOverlay
        case .multiplayerVSScoresDifficultySelection:
            multiplayerVSScoresDifficultySelectionOverlay
        case .multiplayerVSScoresDetail:
            multiplayerVSScoresDetailOverlay
        case .modeSelection:
            modeOverlay(isLandscape: isLandscape)
        case .speedSelection:
            speedOverlay(isLandscape: isLandscape)
        case .scoresMenu:
            scoresMenuOverlay(isLandscape: isLandscape)
        case .settingsMenu:
            settingsMenuOverlay(isLandscape: isLandscape)
        case .skinsMenu:
            skinsMenuOverlay(isLandscape: isLandscape)
        case .onboardingControl:
            onboardingControlOverlay(isLandscape: isLandscape)
        case .soundMenu:
            soundMenuOverlay(isLandscape: isLandscape)
        case .credits:
            creditsOverlay(isLandscape: isLandscape)
        case .controlMenu:
            controlMenuOverlay(isLandscape: isLandscape)
        case .scoresSpeedSelection:
            scoresSpeedSelectionOverlay
        case .scoresDetail:
            scoresDetailOverlay
        case .allSpeedScores:
            allSpeedScoresOverlay
        case .allScores:
            allScoresOverlay
        case .resetScoresConfirmation:
            resetScoresConfirmationOverlay
        case .restartGameConfirmation:
            restartGameConfirmationOverlay
        case .returnToMenuConfirmation:
            returnToMenuConfirmationOverlay
        case .paused:
            pauseOverlay
        case .gameOver:
            gameOverOverlay
        case .gameWon:
            gameWonOverlay
        case .timeUp:
            timeUpOverlay
        case .playing:
            EmptyView()
        }
    }

    func startLegendOrCountdown() {
        let startedGamesKey = "Y2KSnakeStartedGamesCount"
        let startedGamesCount = UserDefaults.standard.integer(forKey: startedGamesKey) + 1
        UserDefaults.standard.set(startedGamesCount, forKey: startedGamesKey)

        guard startedGamesCount % 5 == 0 else {
            startCountdown()
            return
        }

        canMove = false
        countdownText = nil

        let legendCycleIndex = (startedGamesCount / 5 - 1) % 2

        let pillLegendText = "LEGEND SAYS\nTHE PILL\nMAY BRING\n+20 SCORE"

        let scorpionLegendText = selectedMode == .speedRun
            ? "LEGEND SAYS\nSCORPION\nGIVES TIME\nOR TAKES LIFE"
            : "LEGEND SAYS\nTHE SCORPION\nGIVES LIFE\nOR TAKES IT"

        if shouldShowFirstMazeFoodLegend() {
            legendMessageText = "LEGEND SAYS\nMAZE FOOD\nDOES NOT WAIT"
            markFirstMazeFoodLegendSeen()
        } else if shouldShowMissedMazeFoodLegend() {
            legendMessageText = "LEGEND SAYS\nMISSED FOOD\nCOSTS SCORE"
            markMissedMazeFoodLegendSeen()
        } else {
            legendMessageText = legendCycleIndex == 0 ? pillLegendText : scorpionLegendText
        }

        let legendSessionID = gameSessionID
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard gameSessionID == legendSessionID else { return }
            legendMessageText = nil
            guard screen == .playing else { return }
            startCountdown()
        }
    }

    var currentPlayerMazeFoodLegendKey: String {
        "Y2KSnakeMazeFoodLegendSeen_\(currentPlayerName.isEmpty ? "PLAYER" : currentPlayerName)"
    }

    func shouldShowFirstMazeFoodLegend() -> Bool {
        selectedMode == .labyrinth && !UserDefaults.standard.bool(forKey: currentPlayerMazeFoodLegendKey)
    }

    func markFirstMazeFoodLegendSeen() {
        UserDefaults.standard.set(true, forKey: currentPlayerMazeFoodLegendKey)
    }

    var currentPlayerMissedMazeFoodLegendKey: String {
        "Y2KSnakeMissedMazeFoodLegendSeen_\(currentPlayerName.isEmpty ? "PLAYER" : currentPlayerName)"
    }

    func shouldShowMissedMazeFoodLegend() -> Bool {
        selectedMode == .labyrinth && !UserDefaults.standard.bool(forKey: currentPlayerMissedMazeFoodLegendKey)
    }

    func markMissedMazeFoodLegendSeen() {
        UserDefaults.standard.set(true, forKey: currentPlayerMissedMazeFoodLegendKey)
    }

    func startCountdown() {
        countdownToken += 1
        let token = countdownToken

        canMove = false
        countdownText = nil
        countdownEndTime = Date().addingTimeInterval(3.1)
        pausedCountdownRemainingTime = nil
        updateCountdown(token: token)
    }

    func updateCountdown(token: Int) {
        guard countdownToken == token else { return }
        guard screen == .playing else { return }
        guard let countdownEndTime else { return }

        let remainingTime = countdownEndTime.timeIntervalSince(Date())

        if remainingTime <= 0 {
            countdownText = nil
            self.countdownEndTime = nil
            let sessionID = gameSessionID

            DispatchQueue.main.asyncAfter(deadline: .now() + postLevelUpPauseDuration) {
                guard countdownToken == token, gameSessionID == sessionID, screen == .playing else { return }

                lastMoveTime = Date()

	                if selectedMode == .speedRun {
	                    timedRunStartTime = Date()
	                    timedRunSecondsLeft = 60
	                    lastFinalCountdownTickSecond = -1
	                }

	                if isMultiplayerVSMatch {
	                    multiplayerVSStartTime = Date()
	                    multiplayerVSTimeLeft = 300
	                    pausedMultiplayerVSRemainingTime = nil
	                }

	                canMove = true
	            }
            return
        }

        let newText: String
        if remainingTime > 2.4 {
            newText = "3"
        } else if remainingTime > 1.7 {
            newText = "2"
        } else if remainingTime > 1.0 {
            newText = "1"
        } else {
            newText = "GO"
        }

        if countdownText != newText {
            countdownText = newText
            if newText == "GO" {
                SoundManager.shared.playStartGo()
            } else {
                SoundManager.shared.playStartCountdownTick()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            updateCountdown(token: token)
        }
    }

    func pauseCountdownTimer() {
        guard let countdownEndTime else { return }
        guard !canMove else { return }

        pausedCountdownRemainingTime = max(0, countdownEndTime.timeIntervalSince(Date()))
        self.countdownEndTime = nil
        countdownText = nil
        countdownToken += 1
    }

    func resumeCountdownTimerIfNeeded() -> Bool {
        guard let remainingTime = pausedCountdownRemainingTime else { return false }

        pausedCountdownRemainingTime = nil
        countdownToken += 1
        let token = countdownToken
        canMove = false
        countdownEndTime = Date().addingTimeInterval(remainingTime)
        updateCountdown(token: token)
        return true
    }

    func pauseTimedRunTimer() {
        guard selectedMode == .speedRun else { return }
        guard canMove else { return }

        pausedTimedRunRemainingTime = max(0, 60.0 - Date().timeIntervalSince(timedRunStartTime))
    }

    func resumeTimedRunTimerIfNeeded() {
        guard selectedMode == .speedRun else { return }
        guard let remainingTime = pausedTimedRunRemainingTime else { return }

        timedRunSecondsLeft = max(0, Int(ceil(remainingTime)))
        timedRunStartTime = Date().addingTimeInterval(-(60.0 - remainingTime))
        pausedTimedRunRemainingTime = nil
        lastFinalCountdownTickSecond = -1
    }

    func pauseMultiplayerVSTimer() {
        guard isMultiplayerVSMatch else { return }
        guard canMove else { return }

        pausedMultiplayerVSRemainingTime = max(0, 300.0 - Date().timeIntervalSince(multiplayerVSStartTime))
    }

    func resumeMultiplayerVSTimerIfNeeded() {
        guard isMultiplayerVSMatch else { return }
        guard let remainingTime = pausedMultiplayerVSRemainingTime else { return }

        multiplayerVSTimeLeft = max(0, Int(ceil(remainingTime)))
        multiplayerVSStartTime = Date().addingTimeInterval(-(300.0 - remainingTime))
        pausedMultiplayerVSRemainingTime = nil
    }

    var squareBoard: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let playAreaWidth = boardSize
            let cellWidth = playAreaWidth / CGFloat(columns)
            let cellHeight = boardSize / CGFloat(rows)
            let cellSize = min(cellWidth, cellHeight)

            ZStack {
                Rectangle()
                    .fill(lcdColor)
                    .frame(width: playAreaWidth, height: boardSize)

                if screen == .playing || screen == .paused || screen == .gameOver || screen == .gameWon || screen == .timeUp || screen == .multiplayerVSResult {
                    Group {
                        ForEach(0..<rows, id: \.self) { y in
                            ForEach(0..<columns, id: \.self) { x in
                                let point = Point(x: x, y: y)

                if walls.contains(point) {
                    wallPixel(at: point, cellSize: cellSize, cellWidth: cellWidth, cellHeight: cellHeight)
                }

                if food == point {
                    foodPixel(at: point, cellSize: cellSize, cellWidth: cellWidth, cellHeight: cellHeight)
                }
                if !isMultiplayerVSMatch && shouldDrawSuperFood(at: point) {
                    superFoodPixel(at: point, cellSize: cellSize, cellWidth: cellWidth, cellHeight: cellHeight)
                }
                if !isMultiplayerVSMatch && shouldDrawSpeedPill(at: point) {
                    speedPillPixel(at: point, cellSize: cellSize, cellWidth: cellWidth, cellHeight: cellHeight)
                }

                if isMultiplayerVSMatch, aiSnake.contains(point), multiplayerAIVisible {
                    if point == aiSnake.first {
                        aiSnakeHeadPixel(at: point, cellSize: cellSize, cellWidth: cellWidth, cellHeight: cellHeight)
                    } else {
                        aiSnakePixel(at: point, cellSize: cellSize, cellWidth: cellWidth, cellHeight: cellHeight)
                    }
                }

                let shouldDrawPlayerSnake = isMultiplayerVSMatch ? multiplayerPlayerVisible : snakeVisible
                if snake.contains(point), shouldDrawPlayerSnake {
                    if point == snake.first {
                        snakeHeadPixel(at: point, cellSize: cellSize, cellWidth: cellWidth, cellHeight: cellHeight)
                    } else if !isMultiplayerVSMatch && digestionBumps[point] != nil {
                        snakeBellyPixel(at: point, cellSize: cellSize, cellWidth: cellWidth, cellHeight: cellHeight)
                    } else {
                        snakePixel(at: point, cellSize: cellSize, cellWidth: cellWidth, cellHeight: cellHeight)
                    }
                                }
	                            }
	                        }
                    }
                    .frame(width: playAreaWidth, height: boardSize)
                    .clipped()
                }

                thinBoardBorder(width: playAreaWidth, height: boardSize, thickness: boardFrameThickness)

                if screen == .paused || screen == .gameOver || screen == .gameWon || screen == .timeUp || screen == .multiplayerVSResult || countdownText != nil {
                    lcdColor.opacity(0.9)

                    thinBoardBorder(width: playAreaWidth, height: boardSize, thickness: boardFrameThickness)
                }
            }
            .frame(width: playAreaWidth, height: boardSize)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    var playerSelectionOverlay: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let headerHeight: CGFloat = isLandscape ? 42 : 52
            let footerHeight: CGFloat = isLandscape ? 56 : 68
            let verticalPadding: CGFloat = isLandscape ? 5 : 7
            let listHeight = max(70, geometry.size.height - headerHeight - footerHeight - verticalPadding * 2)

            VStack(spacing: 0) {
                pixelText("SELECT PLAYER", size: 22)
                    .frame(height: headerHeight)

                if players.isEmpty {
                    pixelText("NO PLAYERS", size: 16)
                        .frame(height: listHeight)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(players, id: \.self) { player in
                                playerNameButton(player.uppercased()) {
                                    SoundManager.shared.playMenuClick()
                                    selectPlayer(player)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .frame(width: geometry.size.width)
                    .frame(height: listHeight)
                    .contentShape(Rectangle())
                    .clipped()
                }

                Button("NEW PLAYER") {
                    SoundManager.shared.playMenuClick()
                    shouldReturnToPlayerManagementAfterNewPlayer = false
                    newPlayerName = ""
                    screen = .newPlayer
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        isNewPlayerNameFocused = true
                    }
                }
                .buttonStyle(MenuButtonStyle())
                .frame(height: footerHeight)
            }
            .padding(.vertical, verticalPadding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .clipped()
        }
    }

    var playerManagementOverlay: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let headerHeight: CGFloat = isLandscape ? 42 : 52
            let footerHeight: CGFloat = isLandscape ? 76 : 88
            let verticalPadding: CGFloat = isLandscape ? 5 : 7
            let listHeight = max(70, geometry.size.height - headerHeight - footerHeight - verticalPadding * 2)

            VStack(spacing: 0) {
                pixelText("SELECT PLAYER", size: 22)
                    .frame(height: headerHeight)

                if players.isEmpty {
                    pixelText("NO PLAYERS", size: 16)
                        .frame(height: listHeight)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(players, id: \.self) { player in
                                playerNameButton(player.uppercased()) {
                                    SoundManager.shared.playMenuClick()
                                    selectedPlayerForAction = player
                                    screen = .playerActions
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .frame(width: geometry.size.width)
                    .frame(height: listHeight)
                    .contentShape(Rectangle())
                    .clipped()
                }

                VStack(spacing: 8) {
                    Button("NEW PLAYER") {
                        SoundManager.shared.playMenuClick()
                        shouldReturnToPlayerManagementAfterNewPlayer = true
                        newPlayerName = ""
                        screen = .newPlayer
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            isNewPlayerNameFocused = true
                        }
                    }
                    .buttonStyle(MenuButtonStyle())

                    if !currentPlayerName.isEmpty {
                        Button("BACK") {
                            SoundManager.shared.playMenuClick()
                            if shouldReturnToVSAfterPlayerManagement {
                                screen = .multiplayerVSMainMenu
                            } else {
                                screen = shouldReturnToStartAfterPlayerManagement ? .startMenu : .settingsMenu
                            }
                            shouldReturnToStartAfterPlayerManagement = false
                            shouldReturnToVSAfterPlayerManagement = false
                        }
                        .buttonStyle(SmallTextButtonStyle())
                    }
                }
                .padding(.bottom, isLandscape ? 2 : 3)
                .frame(height: footerHeight, alignment: .bottom)
            }
            .padding(.vertical, verticalPadding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .clipped()
        }
    }

    var playerActionsOverlay: some View {
        VStack(spacing: 12) {
            pixelText((selectedPlayerForAction ?? "PLAYER").uppercased(), size: 24)

            Button("PLAY") {
                SoundManager.shared.playMenuClick()
                if let player = selectedPlayerForAction {
                    selectPlayer(player)
                } else {
                    screen = .playerManagement
                }
            }
            .buttonStyle(MenuButtonStyle())

            Button("DELETE") {
                SoundManager.shared.playMenuClick()
                playerToDelete = selectedPlayerForAction
                screen = .deletePlayerConfirmation
            }
            .buttonStyle(MenuButtonStyle())

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                selectedPlayerForAction = nil
                screen = .playerManagement
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 8)
        }
    }

    var newPlayerOverlay: some View {
        VStack(spacing: 12) {
            pixelText("NEW PLAYER", size: 24)

            TextField("NAME", text: $newPlayerName)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundColor(Color.black.opacity(0.78))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .disableAutocorrection(true)
                .focused($isNewPlayerNameFocused)
                .submitLabel(.done)
                .onSubmit {
                    addNewPlayer()
                }
                .onChange(of: newPlayerName) { _, newValue in
                    let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                    let filteredName = newValue.uppercased().filter { allowedCharacters.contains($0) }
                    let limitedName = String(filteredName.prefix(10))

                    if newPlayerName != limitedName {
                        newPlayerName = limitedName
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(lcdColor)
                .overlay(
                    Rectangle()
                        .stroke(Color.black.opacity(0.78), lineWidth: 2)
                )
                .frame(width: 230)

            Button("SAVE") {
                SoundManager.shared.playMenuClick()
                addNewPlayer()
            }
            .buttonStyle(MenuButtonStyle())

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                isNewPlayerNameFocused = false
                newPlayerName = ""
                screen = shouldReturnToPlayerManagementAfterNewPlayer ? .playerManagement : .playerSelection
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 8)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isNewPlayerNameFocused = true
            }
        }
    }

    var deletePlayerOverlay: some View {
        VStack(spacing: 12) {
            pixelText("DELETE PLAYER?", size: 21)
            pixelText((playerToDelete ?? "PLAYER").uppercased(), size: 18)

            Button("YES") {
                SoundManager.shared.playMenuClick()
                deleteSelectedPlayer()
            }
            .buttonStyle(MenuButtonStyle())

            Button("NO") {
                SoundManager.shared.playMenuClick()
                playerToDelete = nil
                screen = .playerActions
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    func playerNameButton(_ title: String, action: @escaping () -> Void) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .black, design: .monospaced))
            .foregroundColor(Color.black.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: 155)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(lcdColor)
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.78), lineWidth: 2)
            )
            .onTapGesture {
                action()
            }
    }

    func adaptiveMenuLayout<Phone: View, Header: View, Content: View, Footer: View>(
        @ViewBuilder phone: @escaping () -> Phone,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) -> some View {
        GeometryReader { geometry in
            if usesExpandedMenuLayout(geometry) {
                VStack(spacing: 0) {
                    header()
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.24, alignment: .bottom)
                        .padding(.bottom, 14)

                    content()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    footer()
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.18, alignment: .top)
                        .padding(.top, 14)
                }
                .padding(.horizontal, 24)
                .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                phone()
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
        }
    }

    func playTypeSelectionOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 9 : 14) {
                playTypeSelectionHeader(isLandscape: isLandscape)
                playTypeSelectionContent
            }
        } header: {
            playTypeSelectionHeader(isLandscape: isLandscape)
        } content: {
            playTypeSelectionContent
        } footer: {
            EmptyView()
        }
        .padding(.top, isLandscape ? 4 : 0)
        .onAppear {
            SoundManager.shared.stopMenuMusic()
        }
    }

    func playTypeSelectionHeader(isLandscape: Bool = false) -> some View {
        pixelText("Y2K SNAKE", size: isLandscape ? 28 : 34)
    }

    var playTypeSelectionContent: some View {
        VStack(spacing: 14) {
            Button("SINGLE PLAYER") {
                SoundManager.shared.playMenuClick()
                screen = .startMenu
            }
            .buttonStyle(MenuButtonStyle())

            Button("MULTIPLAYER") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerMenu
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    func multiplayerMenuOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 7 : 11) {
                multiplayerMenuHeader(isLandscape: isLandscape)
                multiplayerMenuContent(isLandscape: isLandscape)
                multiplayerMenuBackButton
                    .padding(.top, 8)
            }
        } header: {
            multiplayerMenuHeader(isLandscape: isLandscape)
        } content: {
            multiplayerMenuContent(isLandscape: isLandscape)
        } footer: {
            multiplayerMenuBackButton
        }
        .padding(.top, isLandscape ? 2 : 0)
    }

    func multiplayerMenuHeader(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 7 : 11) {
            pixelText("Y2K SNAKE", size: isLandscape ? 28 : 34)
            pixelText("MULTIPLAYER", size: isLandscape ? 15 : 18)
        }
    }

    func multiplayerMenuContent(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 7 : 11) {
            Button("VS SNAKE") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerVSMainMenu
            }
            .buttonStyle(MenuButtonStyle())

            VStack(spacing: isLandscape ? 3 : 5) {
                pixelText("VS PEOPLE", size: isLandscape ? 16 : 18)
                pixelText("COMING SOON", size: isLandscape ? 13 : 15)
            }
        }
    }

    var multiplayerMenuBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            screen = .playTypeSelection
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func multiplayerVSMainMenuOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 6 : 10) {
                multiplayerVSMainMenuHeader(isLandscape: isLandscape)
                multiplayerVSMainMenuContent(isLandscape: isLandscape)
                multiplayerVSMainMenuBackButton
                    .padding(.top, isLandscape ? 2 : 5)
            }
        } header: {
            multiplayerVSMainMenuHeader(isLandscape: isLandscape)
        } content: {
            multiplayerVSMainMenuContent(isLandscape: isLandscape)
        } footer: {
            multiplayerVSMainMenuBackButton
        }
        .padding(.top, isLandscape ? 1 : 0)
        .onAppear {
            SoundManager.shared.playMenuMusic()
        }
    }

    func multiplayerVSMainMenuHeader(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 6 : 10) {
            pixelText("Y2K SNAKE", size: isLandscape ? 27 : 32)
            pixelText("VS SNAKE", size: isLandscape ? 15 : 18)
            pixelText(currentPlayerName.uppercased(), size: isLandscape ? 12 : 14)
        }
    }

    func multiplayerVSMainMenuContent(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 6 : 10) {
            Button("START") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerVSModeSelection
            }
            .buttonStyle(MenuButtonStyle())

            Button("SCORES") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerVSScores
            }
            .buttonStyle(MenuButtonStyle())

            Button("PLAYER") {
                SoundManager.shared.playMenuClick()
                shouldReturnToStartAfterPlayerManagement = false
                shouldReturnToVSAfterPlayerManagement = true
                screen = .playerManagement
            }
            .buttonStyle(MenuButtonStyle())

            Button("SETTINGS") {
                SoundManager.shared.playMenuClick()
                shouldReturnToVSAfterSettings = true
                screen = .settingsMenu
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var multiplayerVSMainMenuBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            screen = .multiplayerMenu
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func multiplayerVSScoresOverlay(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 6 : 8) {
            pixelText("VS SNAKE SCORES", size: isLandscape ? 17 : 19)
            pixelText(currentPlayerName.uppercased(), size: isLandscape ? 13 : 15)

            Button("ALL SCORES") {
                SoundManager.shared.playMenuClick()
                shouldReturnToVSAfterAllScores = true
                screen = .allScores
            }
            .buttonStyle(MenuButtonStyle())

            Button("CLASSIC") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerVSScoresSpeedSelection
            }
            .buttonStyle(MenuButtonStyle())

            VStack(spacing: isLandscape ? 1 : 2) {
                pixelText("MAZE", size: isLandscape ? 15 : 17)
                pixelText("COMING SOON", size: isLandscape ? 10 : 12)
            }

            VStack(spacing: isLandscape ? 1 : 2) {
                pixelText("SPEED RUN", size: isLandscape ? 15 : 17)
                pixelText("COMING SOON", size: isLandscape ? 10 : 12)
            }

            VStack(spacing: isLandscape ? 1 : 2) {
                pixelText("DEATH RACE", size: isLandscape ? 15 : 17)
                pixelText("COMING SOON", size: isLandscape ? 10 : 12)
            }

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                if shouldReturnToPauseAfterScores {
                    shouldReturnToPauseAfterScores = false
                    screen = .paused
                } else {
                    screen = .multiplayerVSMainMenu
                }
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 8)
        }
        .padding(.top, isLandscape ? 2 : 0)
    }

    var multiplayerVSScoresSpeedSelectionOverlay: some View {
        VStack(spacing: 7) {
            pixelText("CLASSIC", size: 21)
            pixelText("SELECT SPEED", size: 14)

            ForEach(1...5, id: \.self) { speed in
                Button("SPEED \(speed)") {
                    SoundManager.shared.playMenuClick()
                    selectedVSScoresSpeed = speed
                    screen = .multiplayerVSScoresDifficultySelection
                }
                .buttonStyle(CompactMenuButtonStyle())
            }

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerVSScores
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 6)
        }
        .padding(.top, 18)
    }

    var multiplayerVSScoresDifficultySelectionOverlay: some View {
        VStack(spacing: 7) {
            pixelText("SELECT AI", size: 21)
            pixelText("VS SNAKE SCORES", size: 14)

            Button("EASY") {
                SoundManager.shared.playMenuClick()
                selectedVSScoresDifficulty = .easy
                screen = .multiplayerVSScoresDetail
            }
            .buttonStyle(MenuButtonStyle())

            Button("NORMAL") {
                SoundManager.shared.playMenuClick()
                selectedVSScoresDifficulty = .normal
                screen = .multiplayerVSScoresDetail
            }
            .buttonStyle(MenuButtonStyle())

            Button("HARD") {
                SoundManager.shared.playMenuClick()
                selectedVSScoresDifficulty = .hard
                screen = .multiplayerVSScoresDetail
            }
            .buttonStyle(MenuButtonStyle())

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerVSScoresSpeedSelection
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 6)
        }
        .padding(.top, 18)
    }

    var multiplayerVSScoresDetailOverlay: some View {
        VStack(spacing: 6) {
            pixelText("CLASSIC S\(selectedVSScoresSpeed) \(selectedVSScoresDifficulty.rawValue)", size: 17)
            pixelText("NO SCORES", size: 18)

            Button("RESET") {
                SoundManager.shared.playMenuClick()
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 6)

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerVSScoresDifficultySelection
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 6)
        }
    }

    func multiplayerVSModeSelectionOverlay(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 5 : 8) {
            pixelText("SELECT GAME", size: isLandscape ? 20 : 23)
            pixelText("VS SNAKE", size: isLandscape ? 15 : 18)

            Button("CLASSIC") {
                SoundManager.shared.playMenuClick()
                selectedMode = .classic
                screen = .multiplayerVSSpeedSelection
            }
            .buttonStyle(MenuButtonStyle())

            VStack(spacing: isLandscape ? 1 : 2) {
                pixelText("MAZE", size: isLandscape ? 15 : 17)
                pixelText("COMING SOON", size: isLandscape ? 10 : 12)
            }

            VStack(spacing: isLandscape ? 1 : 2) {
                pixelText("SPEED RUN", size: isLandscape ? 15 : 17)
                pixelText("COMING SOON", size: isLandscape ? 10 : 12)
            }

            VStack(spacing: isLandscape ? 1 : 2) {
                pixelText("DEATH RACE", size: isLandscape ? 15 : 17)
                pixelText("COMING SOON", size: isLandscape ? 10 : 12)
            }

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerVSMainMenu
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, isLandscape ? 2 : 5)
        }
        .padding(.top, isLandscape ? 0 : 0)
    }

    func multiplayerVSSpeedSelectionOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 10 : 14) {
                multiplayerVSSpeedHeader(isLandscape: isLandscape)
                multiplayerVSSpeedContent
                multiplayerVSSpeedBackButton
                    .padding(.top, 8)
            }
        } header: {
            multiplayerVSSpeedHeader(isLandscape: isLandscape)
        } content: {
            multiplayerVSSpeedContent
        } footer: {
            multiplayerVSSpeedBackButton
        }
    }

    func multiplayerVSSpeedHeader(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 10 : 14) {
            pixelText("SELECT SPEED", size: isLandscape ? 20 : 23)
            pixelText("CLASSIC", size: isLandscape ? 13 : 15)
        }
    }

    var multiplayerVSSpeedContent: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { speed in
                Button("\(speed)") {
                    SoundManager.shared.playMenuClick()
                    selectedSpeed = speed
                    screen = .multiplayerVSAIDifficultySelection
                }
                .buttonStyle(SmallMenuButtonStyle())
            }
        }
    }

    var multiplayerVSSpeedBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            screen = .multiplayerVSModeSelection
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func multiplayerVSAIDifficultySelectionOverlay(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 7 : 11) {
            pixelText("SELECT AI", size: isLandscape ? 20 : 23)
            pixelText("VS SNAKE", size: isLandscape ? 15 : 18)

            Button("EASY") {
                SoundManager.shared.playMenuClick()
                startMultiplayerVSClassicMatch(difficulty: .easy)
            }
            .buttonStyle(MenuButtonStyle())

            Button("NORMAL") {
                SoundManager.shared.playMenuClick()
                startMultiplayerVSClassicMatch(difficulty: .normal)
            }
            .buttonStyle(MenuButtonStyle())

            Button("HARD") {
                SoundManager.shared.playMenuClick()
                startMultiplayerVSClassicMatch(difficulty: .hard)
            }
            .buttonStyle(MenuButtonStyle())

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                screen = .multiplayerVSSpeedSelection
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, isLandscape ? 3 : 6)
        }
        .padding(.top, isLandscape ? 2 : 0)
    }

    var multiplayerVSResultOverlay: some View {
        VStack(spacing: 12) {
            pixelText(multiplayerVSResultTitle, size: 28)
            pixelText("PLAYER \(score)", size: 17)
            pixelText("AI \(aiScore)", size: 17)

            Button("RESTART") {
                SoundManager.shared.playMenuClick()
                startMultiplayerVSClassicMatch()
            }
            .buttonStyle(MenuButtonStyle())

            Button("MENU") {
                SoundManager.shared.playMenuClick()
                finishMultiplayerVSMenuReturn()
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var multiplayerVSResultTitle: String {
        switch multiplayerVSResult {
        case .playerWins:
            return "PLAYER WINS"
        case .aiWins:
            return "AI WINS"
        case .draw:
            return "DRAW"
        }
    }

    func startMenuOverlay(isLandscape: Bool = false) -> some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 320 || geometry.size.width < 300

            if usesExpandedMenuLayout(geometry) {
                VStack(spacing: 0) {
                    startMenuHeader(isLandscape: isLandscape, compact: compact)
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.25, alignment: .bottom)
                        .padding(.bottom, 16)

                    startMenuContent(isLandscape: isLandscape)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    startMenuBackButton
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.18, alignment: .top)
                        .padding(.top, 14)
                }
                .padding(.horizontal, 24)
                .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                VStack(spacing: compact ? 7 : (isLandscape ? 6 : 10)) {
                    startMenuHeader(isLandscape: isLandscape, compact: compact)
                    startMenuContent(isLandscape: isLandscape)
                    startMenuBackButton
                        .padding(.top, compact ? 2 : (isLandscape ? 2 : 5))
                }
                .scaleEffect(compact ? 0.9 : 1.0)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
        }
        .onAppear {
            SoundManager.shared.playMenuMusic()
        }
    }

    func startMenuHeader(isLandscape: Bool = false, compact: Bool = false) -> some View {
        VStack(spacing: compact ? 7 : (isLandscape ? 6 : 10)) {
            pixelText("Y2K SNAKE", size: compact ? 28 : (isLandscape ? 27 : 32))
            pixelText("SINGLE PLAYER", size: isLandscape ? 15 : 18)
            pixelText(currentPlayerName.uppercased(), size: isLandscape ? 12 : 14)
        }
    }

    func startMenuContent(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 6 : 10) {
            Button("START") {
                SoundManager.shared.playMenuClick()
                screen = .modeSelection
            }
            .buttonStyle(MenuButtonStyle())

            Button("SCORES") {
                SoundManager.shared.playMenuClick()
                screen = .scoresMenu
            }
            .buttonStyle(MenuButtonStyle())

            Button("PLAYER") {
                SoundManager.shared.playMenuClick()
                shouldReturnToStartAfterPlayerManagement = true
                shouldReturnToVSAfterPlayerManagement = false
                screen = .playerManagement
            }
            .buttonStyle(MenuButtonStyle())

            Button("SETTINGS") {
                SoundManager.shared.playMenuClick()
                shouldReturnToVSAfterSettings = false
                screen = .settingsMenu
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var startMenuBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            screen = .playTypeSelection
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func settingsMenuOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 8 : 12) {
                settingsMenuHeader(isLandscape: isLandscape)
                settingsMenuContent(isLandscape: isLandscape)
                settingsMenuBackButton
                    .padding(.top, 8)
            }
        } header: {
            settingsMenuHeader(isLandscape: isLandscape)
        } content: {
            settingsMenuContent(isLandscape: isLandscape)
        } footer: {
            settingsMenuBackButton
        }
        .padding(.top, isLandscape ? 3 : 0)
    }

    func settingsMenuHeader(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 8 : 12) {
            pixelText("SETTINGS", size: isLandscape ? 24 : 28)
            pixelText(currentPlayerName.uppercased(), size: isLandscape ? 13 : 15)
        }
    }

    func settingsMenuContent(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 8 : 12) {
            Button("SKINS") {
                SoundManager.shared.playMenuClick()
                skinsReturnContext = shouldReturnToVSAfterSettings ? .vsSettings : .settings
                screen = .skinsMenu
            }
            .buttonStyle(MenuButtonStyle())

            Button("SOUND") {
                SoundManager.shared.playMenuClick()
                shouldReturnToPauseAfterSound = false
                screen = .soundMenu
            }
            .buttonStyle(MenuButtonStyle())

            Button("CONTROL") {
                SoundManager.shared.playMenuClick()
                shouldReturnToPauseAfterControl = false
                screen = .controlMenu
            }
            .buttonStyle(MenuButtonStyle())

            Button("CREDITS") {
                SoundManager.shared.playMenuClick()
                screen = .credits
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var settingsMenuBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            screen = shouldReturnToVSAfterSettings ? .multiplayerVSMainMenu : .startMenu
            shouldReturnToVSAfterSettings = false
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func skinsMenuOverlay(isLandscape: Bool = false) -> some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 330 || geometry.size.height < 360
            let headerHeight: CGFloat = isLandscape ? 40 : 50
            let footerHeight: CGFloat = isLandscape ? 36 : 44
            let verticalPadding: CGFloat = compact ? 6 : (isLandscape ? 8 : 10)
            let listHeight = max(80, geometry.size.height - headerHeight - footerHeight - verticalPadding * 2)
            let contentWidth = max(240, geometry.size.width - (compact ? 34 : 44))

            VStack(spacing: 0) {
                pixelText("SKINS", size: compact ? 23 : (isLandscape ? 22 : 26))
                    .frame(height: headerHeight)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: compact ? 6 : (isLandscape ? 7 : 10)) {
                        ForEach(SnakeSkin.allCases, id: \.self) { skin in
                            snakeSkinRow(skin, availableWidth: contentWidth)
                        }

                        pixelText("MORE SKINS SOON", size: isLandscape ? 12 : 14)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .frame(width: contentWidth)
                .frame(height: listHeight)
                .contentShape(Rectangle())
                .clipped()

                Button("OK") {
                    SoundManager.shared.playMenuClick()
                    completeSkinsSelection()
                }
                .buttonStyle(SmallTextButtonStyle())
                .frame(height: footerHeight)
            }
            .padding(.vertical, verticalPadding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .clipped()
        }
    }

    func snakeSkinRow(_ skin: SnakeSkin, availableWidth: CGFloat) -> some View {
        let compact = availableWidth < 285
        let previewWidth: CGFloat = compact ? 74 : 92
        let nameWidth: CGFloat = compact ? 64 : 72
        let toggleWidth: CGFloat = compact ? 86 : 104
        let rowSpacing: CGFloat = compact ? 6 : 10

        return HStack(spacing: rowSpacing) {
            snakeSkinPreview(skin, selected: selectedSnakeSkin == skin, compact: compact)
                .frame(width: previewWidth, alignment: .leading)
                .clipped()

            pixelText(skin.displayName, size: 12)
                .frame(width: nameWidth, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            if skin.isLocked {
                pixelText("LOCKED", size: 11)
                    .frame(width: toggleWidth, height: 34)
                    .background(lcdColor)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black.opacity(0.78), lineWidth: 2)
                    )
            } else {
                skinSelectionToggle(skin, width: toggleWidth)
            }
        }
        .frame(width: availableWidth)
    }

    func snakeSkinPreview(_ skin: SnakeSkin, selected: Bool, compact: Bool = false) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { index in
                snakeSkinPreviewBodySegment(skin, index: index)
            }

            snakeSkinPreviewHead(skin)
        }
        .scaleEffect((selected ? 1.1 : 1.0) * (compact ? 0.84 : 1.0))
        .frame(width: compact ? 70 : 88, height: 20, alignment: .center)
    }

    func snakeSkinPreviewBodyColor(_ skin: SnakeSkin, index: Int) -> Color {
        if skin == .rainbow {
            let colors: [Color] = [.red, .orange, .yellow, .blue, .purple, .cyan]
            let gameplaySnakeIndex = 6 - index
            return colors[gameplaySnakeIndex % colors.count]
        }

        return snakeColor(for: skin)
    }

    func snakeSkinPreviewBodySegment(_ skin: SnakeSkin, index: Int) -> some View {
        let cellSize: CGFloat = 11

        return ZStack {
            Rectangle()
                .fill(snakeSkinPreviewBodyColor(skin, index: index))
                .frame(width: cellSize * 0.92, height: cellSize * 0.92)

            Rectangle()
                .fill(lcdColor.opacity(0.42))
                .frame(width: cellSize * 0.92, height: cellSize * 0.13)
        }
        .frame(width: cellSize, height: cellSize)
    }

    func snakeSkinPreviewHead(_ skin: SnakeSkin) -> some View {
        let cellSize: CGFloat = 11
        let headColor = skin == .rainbow ? Color.white.opacity(0.92) : snakeColor(for: skin)

        return ZStack {
            Rectangle()
                .fill(headColor)
                .frame(width: cellSize * 1.15, height: cellSize * 1.15)
                .offset(x: -cellSize * 0.08)

            Rectangle()
                .fill(headColor)
                .frame(width: cellSize * 0.5, height: cellSize * 0.58)
                .offset(x: cellSize * 0.48)

            Rectangle()
                .fill(lcdColor)
                .frame(width: cellSize * 0.2, height: cellSize * 0.2)
                .offset(x: cellSize * 0.1, y: -cellSize * 0.32)
        }
        .frame(width: 18, height: 16)
    }

    func skinSelectionToggle(_ skin: SnakeSkin, width: CGFloat = 104) -> some View {
        let isSelected = selectedSnakeSkin == skin

        return Button {
            SoundManager.shared.playMenuClick()
            guard !isSelected else { return }

            selectedSnakeSkin = skin
            saveSelectedSnakeSkin(skin)
        } label: {
            HStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(isSelected ? lcdColor : Color.black.opacity(0.78))
                    pixelText("ON", size: 11)
                }

                ZStack {
                    Rectangle()
                        .fill(isSelected ? Color.black.opacity(0.78) : lcdColor)
                    pixelText("OFF", size: 11)
                }
            }
            .frame(width: width, height: 34)
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.78), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    func soundMenuOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 9 : 14) {
                soundMenuHeader(isLandscape: isLandscape)
                soundMenuContent
                soundMenuBackButton
                    .padding(.top, 8)
            }
        } header: {
            soundMenuHeader(isLandscape: isLandscape)
        } content: {
            soundMenuContent
        } footer: {
            soundMenuBackButton
        }
        .padding(.top, isLandscape ? 4 : 0)
    }

    func soundMenuHeader(isLandscape: Bool = false) -> some View {
        pixelText("SOUND FX", size: isLandscape ? 24 : 28)
    }

    var soundMenuContent: some View {
        VStack(spacing: 14) {
            soundToggleRow(title: "SOUND", isOn: soundEnabled) {
                soundEnabled.toggle()
                UserDefaults.standard.set(soundEnabled, forKey: "Y2KSnakeSoundEnabled")
                if soundEnabled {
                    SoundManager.shared.playMenuClick()
                    if !shouldReturnToPauseAfterSound {
                        SoundManager.shared.playMenuMusic()
                    }
                } else {
                    SoundManager.shared.stopMenuMusic()
                }
            }

            soundToggleRow(title: "HAPTICS", isOn: hapticsEnabled) {
                hapticsEnabled.toggle()
                UserDefaults.standard.set(hapticsEnabled, forKey: "Y2KSnakeHapticsEnabled")
                if hapticsEnabled {
                    playControlHaptic()
                }
            }
        }
    }

    var soundMenuBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            screen = shouldReturnToPauseAfterSound ? .paused : .settingsMenu
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func soundToggleRow(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            pixelText(title, size: 16)
                .frame(width: 95, alignment: .leading)

            Button(action: action) {
                HStack(spacing: 0) {
                    ZStack {
                        Rectangle()
                            .fill(isOn ? lcdColor : Color.black.opacity(0.78))
                        pixelText("ON", size: 13)
                            .foregroundColor(isOn ? Color.black.opacity(0.78) : Color.black.opacity(0.78))
                    }

                    ZStack {
                        Rectangle()
                            .fill(isOn ? Color.black.opacity(0.78) : lcdColor)
                        pixelText("OFF", size: 13)
                            .foregroundColor(isOn ? Color.black.opacity(0.78) : Color.black.opacity(0.78))
                    }
                }
                .frame(width: 104, height: 34)
                .overlay(
                    Rectangle()
                        .stroke(Color.black.opacity(0.78), lineWidth: 2)
                )
            }
        }
    }

    func creditsOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 5 : 7) {
                creditsHeader(isLandscape: isLandscape)
                creditsContent(isLandscape: isLandscape)
                creditsBackButton
                    .padding(.top, isLandscape ? 5 : 8)
            }
        } header: {
            creditsHeader(isLandscape: isLandscape)
        } content: {
            creditsContent(isLandscape: isLandscape)
        } footer: {
            creditsBackButton
        }
        .padding(.top, isLandscape ? 0 : 2)
    }

    func creditsHeader(isLandscape: Bool = false) -> some View {
        pixelText("Y2K SNAKE", size: isLandscape ? 22 : 25)
    }

    func creditsContent(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 5 : 7) {
            pixelText("GAME BY", size: isLandscape ? 12 : 13)
            pixelText("JOHNNY PLAYS", size: isLandscape ? 16 : 18)

            pixelText("CREATED BY", size: isLandscape ? 12 : 13)
            pixelText("SASHATHE", size: isLandscape ? 16 : 18)

            pixelText("GAME DESIGN", size: isLandscape ? 12 : 13)
            pixelText("SASHATHE", size: isLandscape ? 15 : 17)

            pixelText("ART DIRECTION", size: isLandscape ? 12 : 13)
            pixelText("SASHATHE", size: isLandscape ? 15 : 17)

            pixelText("MADE WITH GPT", size: isLandscape ? 13 : 15)
            pixelText("2026", size: isLandscape ? 13 : 15)
        }
    }

    var creditsBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            screen = .settingsMenu
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func modeOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 6 : 8) {
                modeHeader(isLandscape: isLandscape)
                modeContent(isLandscape: isLandscape)
                modeBackButton
                    .padding(.top, 8)
            }
        } header: {
            modeHeader(isLandscape: isLandscape)
        } content: {
            modeContent(isLandscape: isLandscape)
        } footer: {
            modeBackButton
        }
        .padding(.top, isLandscape ? 2 : 0)
    }

    func modeHeader(isLandscape: Bool = false) -> some View {
        pixelText("SELECT GAME", size: isLandscape ? 20 : 23)
    }

    func modeContent(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 6 : 8) {
            Button("1 CLASSIC") {
                SoundManager.shared.playMenuClick()
                selectedMode = .classic
                screen = .speedSelection
            }
            .buttonStyle(MenuButtonStyle())

            Button("2 SPEED RUN") {
                SoundManager.shared.playMenuClick()
                selectedMode = .speedRun
                startNewGame()
            }
            .buttonStyle(MenuButtonStyle())

            Button("3 DEATH RACE") {
                SoundManager.shared.playMenuClick()
                selectedMode = .deathRace
                startNewGame()
            }
            .buttonStyle(MenuButtonStyle())

            Button("4 MAZE") {
                SoundManager.shared.playMenuClick()
                selectedMode = .labyrinth
                screen = .speedSelection
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var modeBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            screen = .startMenu
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func speedOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 10 : 14) {
                speedHeader(isLandscape: isLandscape)
                speedContent
                speedBackButton
                    .padding(.top, 8)
            }
        } header: {
            speedHeader(isLandscape: isLandscape)
        } content: {
            speedContent
        } footer: {
            speedBackButton
        }
    }

    func speedHeader(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 10 : 14) {
            pixelText("SELECT SPEED", size: isLandscape ? 20 : 23)
            pixelText(selectedMode.rawValue, size: isLandscape ? 13 : 15)
        }
    }

    var speedContent: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { speed in
                Button("\(speed)") {
                    SoundManager.shared.playMenuClick()
                    selectedSpeed = speed
                    startNewGame()
                }
                .buttonStyle(SmallMenuButtonStyle())
            }
        }
    }

    var speedBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            screen = .modeSelection
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func scoresMenuOverlay(isLandscape: Bool = false) -> some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 360 || geometry.size.width < 330

            if usesExpandedMenuLayout(geometry) {
                VStack(spacing: 0) {
                    scoresMenuHeader(isLandscape: isLandscape, compact: compact)
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.24, alignment: .bottom)
                        .padding(.bottom, 14)

                    scoresMenuContent(isLandscape: isLandscape)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    scoresMenuBackButton
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.18, alignment: .top)
                        .padding(.top, 14)
                }
                .padding(.horizontal, 24)
                .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                VStack(spacing: compact ? 5 : (isLandscape ? 6 : 8)) {
                    scoresMenuHeader(isLandscape: isLandscape, compact: compact)
                    scoresMenuContent(isLandscape: isLandscape)
                    scoresMenuBackButton
                        .padding(.top, compact ? 2 : 8)
                }
                .scaleEffect(compact ? 0.9 : 1.0)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
        }
    }

    func scoresMenuHeader(isLandscape: Bool = false, compact: Bool = false) -> some View {
        VStack(spacing: compact ? 5 : (isLandscape ? 6 : 8)) {
            pixelText("SINGLE PLAYER SCORES", size: compact ? 16 : (isLandscape ? 17 : 19))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            pixelText(currentPlayerName.uppercased(), size: isLandscape ? 13 : 15)
        }
    }

    func scoresMenuContent(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 6 : 8) {
            Button("ALL SCORES") {
                SoundManager.shared.playMenuClick()
                shouldReturnToVSAfterAllScores = false
                screen = .allScores
            }
            .buttonStyle(MenuButtonStyle())

            Button("1 CLASSIC") {
                SoundManager.shared.playMenuClick()
                selectedScoresMode = .classic
                screen = .scoresSpeedSelection
            }
            .buttonStyle(MenuButtonStyle())

            Button("2 SPEED RUN") {
                SoundManager.shared.playMenuClick()
                selectedScoresMode = .speedRun
                screen = .scoresDetail
            }
            .buttonStyle(MenuButtonStyle())

            Button("3 DEATH RACE") {
                SoundManager.shared.playMenuClick()
                selectedScoresMode = .deathRace
                screen = .scoresDetail
            }
            .buttonStyle(MenuButtonStyle())

            Button("4 MAZE") {
                SoundManager.shared.playMenuClick()
                selectedScoresMode = .labyrinth
                screen = .scoresSpeedSelection
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var scoresMenuBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            if shouldReturnToPauseAfterScores {
                shouldReturnToPauseAfterScores = false
                screen = .paused
            } else {
                screen = .startMenu
            }
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    func controlMenuOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 8 : 10) {
                controlMenuHeader(isLandscape: isLandscape)
                controlMenuContent(isLandscape: isLandscape)
                controlMenuBackButton
                    .padding(.top, 8)
            }
        } header: {
            controlMenuHeader(isLandscape: isLandscape)
        } content: {
            controlMenuContent(isLandscape: isLandscape)
        } footer: {
            controlMenuBackButton
        }
        .padding(.top, isLandscape ? 3 : 0)
    }

    func onboardingControlOverlay(isLandscape: Bool = false) -> some View {
        adaptiveMenuLayout {
            VStack(spacing: isLandscape ? 8 : 10) {
                controlMenuHeader(isLandscape: isLandscape)
                controlMenuContent(isLandscape: isLandscape)
                onboardingControlNextButton
                    .padding(.top, 8)
            }
        } header: {
            controlMenuHeader(isLandscape: isLandscape)
        } content: {
            controlMenuContent(isLandscape: isLandscape)
        } footer: {
            onboardingControlNextButton
        }
        .padding(.top, isLandscape ? 3 : 0)
    }

    func controlMenuHeader(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 8 : 10) {
            pixelText("CONTROL", size: isLandscape ? 24 : 27)
            pixelText(selectedControlLayout.rawValue, size: isLandscape ? 14 : 16)
        }
    }

    func controlMenuContent(isLandscape: Bool = false) -> some View {
        VStack(spacing: isLandscape ? 8 : 10) {
            Button("CLASSIC") {
                SoundManager.shared.playMenuClick()
                selectControlLayout(.classic)
            }
            .buttonStyle(MenuButtonStyle())

            Button("RIGHT") {
                SoundManager.shared.playMenuClick()
                selectControlLayout(.right)
            }
            .buttonStyle(MenuButtonStyle())

            Button("LEFT") {
                SoundManager.shared.playMenuClick()
                selectControlLayout(.left)
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var controlMenuBackButton: some View {
        Button("BACK") {
            SoundManager.shared.playMenuClick()
            let returnToPause = shouldReturnToPauseAfterControl
            shouldReturnToPauseAfterControl = false
            screen = returnToPause ? .paused : .settingsMenu
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    var onboardingControlNextButton: some View {
        Button("NEXT") {
            SoundManager.shared.playMenuClick()
            completeOnboardingControlSelection()
        }
        .buttonStyle(SmallTextButtonStyle())
    }

    var scoresSpeedSelectionOverlay: some View {
        VStack(spacing: 7) {
            pixelText(selectedScoresMode.rawValue, size: 21)
            pixelText("SELECT SPEED", size: 14)

            ForEach(1...5, id: \.self) { speed in
                Button("SPEED \(speed)") {
                    SoundManager.shared.playMenuClick()
                    selectedScoresSpeed = speed
                    screen = .scoresDetail
                }
                .buttonStyle(CompactMenuButtonStyle())
            }

            Button("ALL SPEED SCORES") {
                SoundManager.shared.playMenuClick()
                screen = .allSpeedScores
            }
            .buttonStyle(CompactMenuButtonStyle())

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                screen = .scoresMenu
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 6)
        }
        .padding(.top, 18)
    }

    var allSpeedScoresOverlay: some View {
        VStack(spacing: 6) {
            pixelText("ALL SPEED SCORES", size: 18)
            pixelText(selectedScoresMode.rawValue, size: 15)

            let list = allSpeedScores(for: selectedScoresMode)

            if list.isEmpty {
                pixelText("NO SCORES", size: 18)
            } else {
                ForEach(Array(list.enumerated()), id: \.offset) { index, item in
                    allScoreRow(index: index, entry: item.entry, modeLabel: item.modeLabel)
                }
            }

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                screen = .scoresSpeedSelection
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 6)
        }
    }


    var scoresDetailOverlay: some View {
        VStack(spacing: 6) {
            if selectedScoresMode == .classic || selectedScoresMode == .labyrinth {
                pixelText("\(selectedScoresMode.rawValue) S\(selectedScoresSpeed)", size: 20)

                let list = LeaderboardManager.load(for: selectedScoresMode, speed: selectedScoresSpeed)

                if list.isEmpty {
                    pixelText("NO SCORES", size: 18)
                } else {
                    ForEach(Array(list.enumerated()), id: \.offset) { index, entry in
                        scoreRow(index: index, entry: entry)
                    }
                }
            } else {
                pixelText(selectedScoresMode.rawValue, size: 22)

                let list = LeaderboardManager.load(for: selectedScoresMode, speed: nil)

                if list.isEmpty {
                    pixelText("NO SCORES", size: 18)
                } else {
                    ForEach(Array(list.enumerated()), id: \.offset) { index, entry in
                        scoreRow(index: index, entry: entry)
                    }
                }
            }

            Button("RESET") {
                SoundManager.shared.playMenuClick()
                screen = .resetScoresConfirmation
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 6)

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                if selectedScoresMode == .classic || selectedScoresMode == .labyrinth {
                    screen = .scoresSpeedSelection
                } else {
                    screen = .scoresMenu
                }
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 6)
        }
    }

    var allScoresOverlay: some View {
        VStack(spacing: 6) {
            pixelText("ALL SCORES", size: 22)

            if shouldReturnToVSAfterAllScores {
                pixelText("VS SNAKE", size: 15)
                pixelText("NO SCORES", size: 18)
            } else {
                let list = allSinglePlayerScores()

                if list.isEmpty {
                    pixelText("NO SCORES", size: 18)
                } else {
                    ForEach(Array(list.enumerated()), id: \.offset) { index, item in
                        allScoreRow(index: index, entry: item.entry, modeLabel: item.modeLabel)
                    }
                }
            }

            Button("BACK") {
                SoundManager.shared.playMenuClick()
                screen = shouldReturnToVSAfterAllScores ? .multiplayerVSScores : .scoresMenu
            }
            .buttonStyle(SmallTextButtonStyle())
            .padding(.top, 6)
        }
    }

    var resetScoresConfirmationOverlay: some View {
        VStack(spacing: 12) {
            pixelText("RESET SCORES?", size: 22)
            pixelText("ARE YOU SURE?", size: 16)

            Button("YES") {
                SoundManager.shared.playMenuClick()
                LeaderboardManager.resetAll()
                if selectedScoresMode == .classic || selectedScoresMode == .labyrinth {
                    screen = .scoresSpeedSelection
                } else {
                    screen = .scoresMenu
                }
            }
            .buttonStyle(MenuButtonStyle())

            Button("NO") {
                SoundManager.shared.playMenuClick()
                screen = .scoresDetail
            }
            .buttonStyle(MenuButtonStyle())
            .padding(.top, 8)
        }
    }

    func allSinglePlayerScores() -> [(entry: ScoreEntry, modeLabel: String)] {
        var list: [(entry: ScoreEntry, modeLabel: String)] = []

        for speed in 1...5 {
            list.append(contentsOf: LeaderboardManager.load(for: .classic, speed: speed).map {
                (entry: $0, modeLabel: "CLS S\(speed)")
            })
            list.append(contentsOf: LeaderboardManager.load(for: .labyrinth, speed: speed).map {
                (entry: $0, modeLabel: "MAZ S\(speed)")
            })
        }

        list.append(contentsOf: LeaderboardManager.load(for: .speedRun, speed: nil).map {
            (entry: $0, modeLabel: "SPD")
        })
        list.append(contentsOf: LeaderboardManager.load(for: .deathRace, speed: nil).map {
            (entry: $0, modeLabel: "DTH")
        })

        return Array(list.sorted { $0.entry.score > $1.entry.score }.prefix(5))
    }

    func allSpeedScores(for mode: GameMode) -> [(entry: ScoreEntry, modeLabel: String)] {
        guard mode == .classic || mode == .labyrinth else { return [] }

        let modeLabel = mode == .classic ? "CLS" : "MAZ"
        var list: [(entry: ScoreEntry, modeLabel: String)] = []

        for speed in 1...5 {
            list.append(contentsOf: LeaderboardManager.load(for: mode, speed: speed).map {
                (entry: $0, modeLabel: "\(modeLabel) S\(speed)")
            })
        }

        return Array(list.sorted { $0.entry.score > $1.entry.score }.prefix(5))
    }

    func scoreRow(index: Int, entry: ScoreEntry) -> some View {
        HStack(spacing: 0) {
            pixelText("\(index + 1)", size: 14)
                .frame(width: 24, alignment: .leading)

            pixelText(entry.playerName.uppercased(), size: 14)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            pixelText("\(entry.score)", size: 14)
                .frame(width: 44, alignment: .trailing)
        }
        .frame(width: 188, alignment: .leading)
    }

    func allScoreRow(index: Int, entry: ScoreEntry, modeLabel: String) -> some View {
        HStack(spacing: 0) {
            pixelText("\(index + 1)", size: 12)
                .frame(width: 18, alignment: .leading)

            pixelText(entry.playerName.uppercased(), size: 12)
                .frame(width: 82, alignment: .leading)
                .lineLimit(1)

            pixelText("\(entry.score)", size: 12)
                .frame(width: 42, alignment: .trailing)

            pixelText(modeLabel, size: 12)
                .frame(width: 58, alignment: .trailing)
        }
        .frame(width: 200, alignment: .leading)
    }

    var pauseOverlay: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 360 || geometry.size.width < 330

            VStack(spacing: compact ? 7 : 10) {
                pixelText("PAUSE", size: compact ? 28 : 32)

                Button("RESTART") {
                    SoundManager.shared.playMenuClick()
                    screen = .restartGameConfirmation
                }
                .buttonStyle(MenuButtonStyle())

            Button("SCORES") {
                SoundManager.shared.playMenuClick()
                shouldReturnToPauseAfterScores = true
                if isMultiplayerVSMatch {
                    shouldReturnToVSAfterAllScores = false
                    screen = .multiplayerVSScores
                } else {
                    shouldReturnToVSAfterAllScores = false
                    screen = .scoresMenu
                }
            }
                .buttonStyle(MenuButtonStyle())

                Button("CONTROL") {
                    SoundManager.shared.playMenuClick()
                    shouldReturnToPauseAfterControl = true
                    screen = .controlMenu
                }
                .buttonStyle(MenuButtonStyle())

                Button("SOUND") {
                    SoundManager.shared.playMenuClick()
                    shouldReturnToPauseAfterSound = true
                    screen = .soundMenu
                }
                .buttonStyle(MenuButtonStyle())

                Button("MENU") {
                    SoundManager.shared.playMenuClick()
                    screen = .returnToMenuConfirmation
                }
                .buttonStyle(MenuButtonStyle())
            }
            .scaleEffect(compact ? 0.92 : 1.0)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }

    var restartGameConfirmationOverlay: some View {
        VStack(spacing: 12) {
            pixelText("RESTART GAME?", size: 22)
            pixelText("ARE YOU SURE?", size: 16)

            Button("YES") {
                SoundManager.shared.playMenuClick()
                if isMultiplayerVSMatch {
                    startMultiplayerVSClassicMatch()
                } else {
                    startNewGame()
                }
            }
            .buttonStyle(MenuButtonStyle())

            Button("NO") {
                SoundManager.shared.playMenuClick()
                screen = .paused
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var returnToMenuConfirmationOverlay: some View {
        VStack(spacing: 12) {
            pixelText("RETURN TO MENU?", size: 20)
            pixelText("ARE YOU SURE?", size: 16)

            Button("YES") {
                SoundManager.shared.playMenuClick()
                if !isMultiplayerVSMatch {
                    finishCurrentRunAndSaveScore()
                }
                shouldReturnToPauseAfterControl = false
                shouldReturnToPauseAfterSound = false
                shouldReturnToPauseAfterScores = false
                resetPillEffect()
                if isMultiplayerVSMatch {
                    finishMultiplayerVSMenuReturn()
                } else {
                    screen = .startMenu
                }
            }
            .buttonStyle(MenuButtonStyle())

            Button("NO") {
                SoundManager.shared.playMenuClick()
                screen = .paused
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var gameOverOverlay: some View {
        VStack(spacing: 12) {
            pixelText("GAME OVER", size: 28)
            if newRecordAchieved {
                pixelText("NEW RECORD!", size: 17)
            }
            pixelText("SCORE \(score)", size: 18)

            Button("RESTART") {
                SoundManager.shared.playMenuClick()
                startNewGame()
            }
            .buttonStyle(MenuButtonStyle())

            Button("MENU") {
                SoundManager.shared.playMenuClick()
                resetPillEffect()
                screen = .startMenu
            }
            .buttonStyle(MenuButtonStyle())

        }
    }

    var gameWonOverlay: some View {
        VStack(spacing: 12) {
            pixelText("YOU WIN", size: 30)
            if newRecordAchieved {
                pixelText("NEW RECORD!", size: 17)
            }
            pixelText("SCORE \(score)", size: 18)

            Button("RESTART") {
                SoundManager.shared.playMenuClick()
                startNewGame()
            }
            .buttonStyle(MenuButtonStyle())

            Button("MENU") {
                SoundManager.shared.playMenuClick()
                resetPillEffect()
                screen = .startMenu
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    var timeUpOverlay: some View {
        VStack(spacing: 12) {
            pixelText("TIME UP", size: 30)
            if newRecordAchieved {
                pixelText("NEW RECORD!", size: 17)
            }
            pixelText("SCORE \(score)", size: 18)

            Button("RESTART") {
                SoundManager.shared.playMenuClick()
                startNewGame()
            }
            .buttonStyle(MenuButtonStyle())

            Button("MENU") {
                SoundManager.shared.playMenuClick()
                resetPillEffect()
                screen = .startMenu
            }
            .buttonStyle(MenuButtonStyle())
        }
    }

    func pauseButton(isLandscape: Bool) -> some View {
        let title = screen == .paused ? "CONTINUE" : "PAUSE"
        let fontSize: CGFloat = isLandscape
            ? (title == "PAUSE" ? 18 : 22)
            : 20
        let labelWidth: CGFloat? = isLandscape ? nil : 100
        let buttonWidth: CGFloat? = isLandscape ? nil : 168
        let buttonHeight: CGFloat? = isLandscape ? nil : 48
        let isDisabled = isRespawning || (screen == .playing && !canMove) || countdownText != nil

        return Button {
            SoundManager.shared.playMenuClick()

            if screen == .paused {
                screen = .playing
                canMove = false
                let sessionID = gameSessionID

	                DispatchQueue.main.asyncAfter(deadline: .now() + postLevelUpPauseDuration) {
	                    guard gameSessionID == sessionID, screen == .playing else { return }

	                    resumePillEffectTimer()
	                    if resumeCountdownTimerIfNeeded() {
	                        return
	                    } else {
	                        resumeTimedRunTimerIfNeeded()
	                        resumeMultiplayerVSTimerIfNeeded()
	                    }

	                    lastMoveTime = Date()
	                    canMove = true
	                }
            } else {
	                pausePillEffectTimer()
	                pauseCountdownTimer()
	                pauseTimedRunTimer()
	                pauseMultiplayerVSTimer()
	                screen = .paused
	            }
        } label: {
            Text(title)
                .font(.system(size: fontSize, weight: .black, design: .monospaced))
                .frame(width: labelWidth)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .buttonStyle(PauseButtonStyle())
        .frame(width: buttonWidth, height: buttonHeight)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    @ViewBuilder
    var controlPad: some View {
        switch selectedControlLayout {
        case .classic:
            classicControlPad
        case .right:
            rightControlPad
        case .left:
            leftControlPad
        }
    }

    var classicControlPad: some View {
        VStack(spacing: 12) {
            directionButton("↑", .up)

            HStack(spacing: 70) {
                directionButton("←", .left)
                directionButton("→", .right)
            }

            directionButton("↓", .down)
        }
    }

    var rightControlPad: some View {
        HStack(spacing: 80) {
            HStack(spacing: 12) {
                directionButton("←", .left)
                directionButton("→", .right)
            }

            VStack(spacing: 12) {
                directionButton("↑", .up)
                directionButton("↓", .down)
            }
        }
    }

    var leftControlPad: some View {
        HStack(spacing: 80) {
            VStack(spacing: 12) {
                directionButton("↑", .up)
                directionButton("↓", .down)
            }

            HStack(spacing: 12) {
                directionButton("←", .left)
                directionButton("→", .right)
            }
        }
    }

    func playControlHaptic() {
        guard hapticsEnabled else { return }
        controlHapticGenerator.impactOccurred(intensity: 0.45)
        controlHapticGenerator.prepare()
    }

    func prewarmHaptics() {
        guard hapticsEnabled else { return }
        controlHapticGenerator.prepare()
    }

    func playFoodHaptic() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.35)
    }

    func playSuperFoodHaptic() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.85)
    }

    func playExtraLifeHaptic() {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func playHitHaptic() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred(intensity: 1.0)
    }

    func playLevelUpHaptic() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.8)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            guard hapticsEnabled else { return }
            let secondGenerator = UIImpactFeedbackGenerator(style: .rigid)
            secondGenerator.impactOccurred(intensity: 0.95)
        }
    }


    @ViewBuilder
    func directionButton(_ title: String, _ direction: Direction) -> some View {
        Button(title) {
            if changeDirection(direction) {
                playControlHaptic()
            }
        }
        .buttonStyle(RetroButtonStyle())
    }

    @ViewBuilder
    var leftLandscapeControls: some View {
        switch selectedControlLayout {
        case .classic:
            ZStack {
                directionButton("←", .left)
                    .offset(x: -26, y: -44)

                directionButton("↓", .down)
                    .offset(x: 26, y: 44)
            }
            .frame(width: 150, height: 170)
        case .right:
            HStack(spacing: 12) {
                directionButton("←", .left)
                directionButton("→", .right)
            }
        case .left:
            VStack(spacing: 12) {
                directionButton("↑", .up)
                directionButton("↓", .down)
            }
        }
    }

    @ViewBuilder
    var rightLandscapeControls: some View {
        switch selectedControlLayout {
        case .classic:
            ZStack {
                directionButton("↑", .up)
                    .offset(x: -26, y: -44)

                directionButton("→", .right)
                    .offset(x: 26, y: 44)
            }
            .frame(width: 150, height: 170)
        case .right:
            VStack(spacing: 12) {
                directionButton("↑", .up)
                directionButton("↓", .down)
            }
        case .left:
            HStack(spacing: 12) {
                directionButton("←", .left)
                directionButton("→", .right)
            }
        }
    }


    func pixelPosition(for point: Point, cellWidth: CGFloat, cellHeight: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(point.x) * cellWidth + cellWidth / 2,
            y: CGFloat(point.y) * cellHeight + cellHeight / 2
        )
    }


    func rainbowColor(for point: Point) -> Color {
        let rainbowColors: [Color] = [.red, .orange, .yellow, .blue, .purple, .cyan]
        let index = snake.firstIndex(of: point) ?? 0
        return rainbowColors[index % rainbowColors.count]
    }

    func alternateRainbowColor(for point: Point) -> Color {
        let alternateColors: [Color] = [.cyan, .pink, .green, .white, .orange, .purple]
        let index = snake.firstIndex(of: point) ?? 0
        return alternateColors[index % alternateColors.count]
    }

    func snakeColor(for skin: SnakeSkin) -> Color {
        switch skin {
        case .black, .rainbow:
            return Color.black.opacity(0.80)
        case .white:
            return Color.white.opacity(0.90)
        case .red:
            return Color.red.opacity(0.88)
        case .yellow:
            return Color.yellow.opacity(0.95)
        case .blue:
            return Color.blue.opacity(0.88)
        }
    }

    func snakeBodyColor(for point: Point) -> Color {
        if activePillEffect == .rainbow {
            return selectedSnakeSkin == .rainbow
                ? alternateRainbowColor(for: point)
                : rainbowColor(for: point)
        }

        if selectedSnakeSkin == .rainbow {
            return rainbowColor(for: point)
        }

        return snakeColor(for: selectedSnakeSkin)
    }

    func snakeHeadColor() -> Color {
        if activePillEffect == .rainbow {
            return selectedSnakeSkin == .rainbow
                ? Color(red: 0.18, green: 0.05, blue: 0.30).opacity(0.95)
                : Color.white.opacity(0.92)
        }

        if selectedSnakeSkin == .rainbow {
            return Color.white.opacity(0.92)
        }

        return snakeColor(for: selectedSnakeSkin)
    }

    func snakeOpenMouthColor() -> Color {
        if activePillEffect == .rainbow && selectedSnakeSkin != .rainbow {
            return Color.black.opacity(0.38)
        }

        return lcdColor
    }

    func snakePixel(at point: Point, cellSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(snakeBodyColor(for: point))
                .frame(width: cellSize * 0.92, height: cellSize * 0.92)

            Rectangle()
                .fill(lcdColor.opacity(0.42))
                .frame(width: cellSize * 0.92, height: cellSize * 0.13)
        }
        .scaleEffect(activePillEffect == .speed ? speedPillPulseScale : 1.0)
        .opacity(activePillEffect == .speed ? speedPillFlickerOpacity : 1.0)
        .position(pixelPosition(for: point, cellWidth: cellWidth, cellHeight: cellHeight))
    }

    func aiSnakeColor() -> Color {
        selectedSnakeSkin == .black
            ? Color.white.opacity(0.90)
            : Color.black.opacity(0.80)
    }

    func aiSnakeOpenMouthColor() -> Color {
        selectedSnakeSkin == .black
            ? Color.black.opacity(0.38)
            : lcdColor
    }

    func aiSnakePixel(at point: Point, cellSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(aiSnakeColor())
                .frame(width: cellSize * 0.92, height: cellSize * 0.92)

            Rectangle()
                .fill(lcdColor.opacity(0.42))
                .frame(width: cellSize * 0.92, height: cellSize * 0.13)
        }
        .position(pixelPosition(for: point, cellWidth: cellWidth, cellHeight: cellHeight))
    }

    func aiSnakeHeadPixel(at point: Point, cellSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        ZStack {
            if isFoodInFrontOfAIHead() {
                Rectangle()
                    .fill(aiSnakeColor())
                    .frame(width: cellSize * 1.1, height: cellSize * 1.2)
                    .offset(x: -cellSize * 0.12)

                Rectangle()
                    .fill(aiSnakeColor())
                    .frame(width: cellSize * 0.78, height: cellSize * 0.32)
                    .offset(x: cellSize * 0.48, y: -cellSize * 0.38)

                Rectangle()
                    .fill(aiSnakeColor())
                    .frame(width: cellSize * 0.78, height: cellSize * 0.32)
                    .offset(x: cellSize * 0.48, y: cellSize * 0.38)

                Rectangle()
                    .fill(aiSnakeOpenMouthColor())
                    .frame(width: cellSize * 0.72, height: cellSize * 0.48)
                    .offset(x: cellSize * 0.5)

                Rectangle()
                    .fill(lcdColor)
                    .frame(width: cellSize * 0.22, height: cellSize * 0.22)
                    .offset(x: cellSize * 0.08, y: -cellSize * 0.34)
            } else {
                Rectangle()
                    .fill(aiSnakeColor())
                    .frame(width: cellSize * 1.15, height: cellSize * 1.15)
                    .offset(x: -cellSize * 0.08)

                Rectangle()
                    .fill(aiSnakeColor())
                    .frame(width: cellSize * 0.5, height: cellSize * 0.58)
                    .offset(x: cellSize * 0.48)

                Rectangle()
                    .fill(lcdColor)
                    .frame(width: cellSize * 0.2, height: cellSize * 0.2)
                    .offset(x: cellSize * 0.1, y: -cellSize * 0.32)
            }
        }
        .rotationEffect(rotation(for: aiDirection))
        .position(pixelPosition(for: point, cellWidth: cellWidth, cellHeight: cellHeight))
    }

    func snakeBellyPixel(at point: Point, cellSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        ZStack {
            // Bigger swallowed-food segment, but still made from pixel parts.
            Rectangle()
                .fill(snakeBodyColor(for: point))
                .frame(width: cellSize * 1.34, height: cellSize * 1.34)

            // Small LCD cross in the middle, so it does not look like one solid brick.
            Rectangle()
                .fill(lcdColor)
                .frame(width: cellSize * 1.34, height: cellSize * 0.12)

            Rectangle()
                .fill(lcdColor)
                .frame(width: cellSize * 0.12, height: cellSize * 1.34)

            // Dark core keeps it connected to the snake body.
            Rectangle()
                .fill(snakeBodyColor(for: point).opacity(0.95))
                .frame(width: cellSize * 0.74, height: cellSize * 0.74)

            // Tiny LCD pixel in the very center, like an old LCD gap.
            Rectangle()
                .fill(lcdColor.opacity(0.85))
                .frame(width: cellSize * 0.18, height: cellSize * 0.18)
        }
        .scaleEffect(activePillEffect == .speed ? speedPillPulseScale : 1.0)
        .opacity(activePillEffect == .speed ? speedPillFlickerOpacity : 1.0)
        .position(pixelPosition(for: point, cellWidth: cellWidth, cellHeight: cellHeight))
    }

    func wallPixel(at point: Point, cellSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.80))
                .frame(width: cellSize * 0.95, height: cellSize * 0.95)

            Rectangle()
                .fill(lcdColor.opacity(0.92))
                .frame(width: cellSize * 0.46, height: cellSize * 0.46)

            Rectangle()
                .fill(Color.black.opacity(0.72))
                .frame(width: cellSize * 0.16, height: cellSize * 0.16)
        }
        .position(pixelPosition(for: point, cellWidth: cellWidth, cellHeight: cellHeight))
    }

    func snakeHeadPixel(at point: Point, cellSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        ZStack {
            if isFoodInFrontOfHead() {
                // Profile head with open mouth. Base direction is RIGHT, then rotated.
                Rectangle()
                    .fill(snakeHeadColor())
                    .frame(width: cellSize * 1.1, height: cellSize * 1.2)
                    .offset(x: -cellSize * 0.12)

                // Upper jaw
                Rectangle()
                    .fill(snakeHeadColor())
                    .frame(width: cellSize * 0.78, height: cellSize * 0.32)
                    .offset(x: cellSize * 0.48, y: -cellSize * 0.38)

                // Lower jaw
                Rectangle()
                    .fill(snakeHeadColor())
                    .frame(width: cellSize * 0.78, height: cellSize * 0.32)
                    .offset(x: cellSize * 0.48, y: cellSize * 0.38)

                // Open mouth hole
                Rectangle()
                    .fill(snakeOpenMouthColor())
                    .frame(width: cellSize * 0.72, height: cellSize * 0.48)
                    .offset(x: cellSize * 0.5)

                // Top eye
                Rectangle()
                    .fill(lcdColor)
                    .frame(width: cellSize * 0.22, height: cellSize * 0.22)
                    .offset(x: cellSize * 0.08, y: -cellSize * 0.34)
            } else {
                // Closed profile head with small snout.
                Rectangle()
                    .fill(snakeHeadColor())
                    .frame(width: cellSize * 1.15, height: cellSize * 1.15)
                    .offset(x: -cellSize * 0.08)

                Rectangle()
                    .fill(snakeHeadColor())
                    .frame(width: cellSize * 0.5, height: cellSize * 0.58)
                    .offset(x: cellSize * 0.48)

                // Top eye
                Rectangle()
                    .fill(lcdColor)
                    .frame(width: cellSize * 0.2, height: cellSize * 0.2)
                    .offset(x: cellSize * 0.1, y: -cellSize * 0.32)
            }
        }
        .rotationEffect(rotationForDirection())
        .scaleEffect(activePillEffect == .speed ? speedPillPulseScale : 1.0)
        .opacity(activePillEffect == .speed ? speedPillFlickerOpacity : 1.0)
        .position(pixelPosition(for: point, cellWidth: cellWidth, cellHeight: cellHeight))
    }



    func mouthShape(cellSize: CGFloat) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: cellSize * 0.95, y: cellSize * 0.15))
        path.addLine(to: CGPoint(x: cellSize * 0.45, y: cellSize * 0.5))
        path.addLine(to: CGPoint(x: cellSize * 0.95, y: cellSize * 0.85))
        path.closeSubpath()

        return path
    }

    func rotationForDirection() -> Angle {
        rotation(for: direction)
    }

    func rotation(for moveDirection: Direction) -> Angle {
        switch moveDirection {
        case .right:
            return .degrees(0)
        case .down:
            return .degrees(90)
        case .left:
            return .degrees(180)
        case .up:
            return .degrees(270)
        }
    }

    func isFoodInFrontOfHead() -> Bool {
        guard let head = snake.first else { return false }

        var frontPoint = head

        switch direction {
        case .up:
            frontPoint = Point(x: head.x, y: head.y - 1)
        case .down:
            frontPoint = Point(x: head.x, y: head.y + 1)
        case .left:
            frontPoint = Point(x: head.x - 1, y: head.y)
        case .right:
            frontPoint = Point(x: head.x + 1, y: head.y)
        }

        if frontPoint.x < 0 {
            frontPoint = Point(x: columns - 1, y: frontPoint.y)
        } else if frontPoint.x >= columns {
            frontPoint = Point(x: 0, y: frontPoint.y)
        }

        if frontPoint.y < 0 {
            frontPoint = Point(x: frontPoint.x, y: rows - 1)
        } else if frontPoint.y >= rows {
            frontPoint = Point(x: frontPoint.x, y: 0)
        }

        return frontPoint == food
            || (superFoodVisible && frontPoint == superFood)
            || (speedPillVisible && frontPoint == speedPill)
    }

    func isFoodInFrontOfAIHead() -> Bool {
        guard let head = aiSnake.first else { return false }
        return wrappedPoint(from: head, moving: aiDirection) == food
    }

    func shouldDrawSuperFood(at point: Point) -> Bool {
        guard superFoodVisible, superFood == point else { return false }

        let elapsed = Date().timeIntervalSince(superFoodSpawnTime)
        let remaining = superFoodDuration - elapsed

        if remaining > 1.5 {
            return true
        }

        return (superFoodBlinkFrame / 6) % 2 == 0
    }

    func shouldDrawSpeedPill(at point: Point) -> Bool {
        guard speedPillVisible, speedPill == point else { return false }

        let elapsed = Date().timeIntervalSince(speedPillSpawnTime)
        let remaining = speedPillDuration - elapsed

        if remaining > 1.5 {
            return true
        }

        return (speedPillBlinkFrame / 6) % 2 == 0
    }

    func foodPixel(at point: Point, cellSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        return ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.78))
                .frame(width: cellSize * 0.35, height: cellSize * 0.9)

            Rectangle()
                .fill(Color.black.opacity(0.78))
                .frame(width: cellSize * 0.9, height: cellSize * 0.35)
        }
        .opacity(mazeFoodOpacity(for: point))
        .position(pixelPosition(for: point, cellWidth: cellWidth, cellHeight: cellHeight))
    }

    let mazeFoodDuration: TimeInterval = 20.0
    let mazeFoodBlinkDuration: TimeInterval = 3.0
    @State private var mazeFoodSpawnTime = Date()
    @State private var mazeFoodBlinkFrame = 0

    func resetMazeFoodTimer() {
        guard selectedMode == .labyrinth else { return }
        mazeFoodSpawnTime = Date()
        mazeFoodBlinkFrame = 0
    }

    func mazeFoodOpacity(for point: Point) -> Double {
        guard selectedMode == .labyrinth else { return 1.0 }
        guard point == food else { return 1.0 }

        let elapsed = Date().timeIntervalSince(mazeFoodSpawnTime)
        let remaining = mazeFoodDuration - elapsed

        if remaining > mazeFoodBlinkDuration {
            return 1.0
        }

        return (mazeFoodBlinkFrame / 6) % 2 == 0 ? 1.0 : 0.0
    }

    func superFoodPixel(at point: Point, cellSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        ZStack {
            switch superFoodType {
            case .butterfly:
                butterflyPixel(cellSize: cellSize)
            case .bug:
                bugPixel(cellSize: cellSize)
            case .caterpillar:
                caterpillarPixel(cellSize: cellSize)
            case .spider:
                spiderPixel(cellSize: cellSize)
            case .scorpion:
                scorpionPixel(cellSize: cellSize)
            }
        }
        .position(pixelPosition(for: point, cellWidth: cellWidth, cellHeight: cellHeight))
    }

    func butterflyPixel(cellSize: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.48, height: cellSize * 0.48)
                .offset(x: -cellSize * 0.38, y: -cellSize * 0.22)

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.48, height: cellSize * 0.48)
                .offset(x: cellSize * 0.38, y: -cellSize * 0.22)

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.38, height: cellSize * 0.38)
                .offset(x: -cellSize * 0.34, y: cellSize * 0.28)

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.38, height: cellSize * 0.38)
                .offset(x: cellSize * 0.34, y: cellSize * 0.28)

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.26, height: cellSize * 1.12)

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.36, height: cellSize * 0.28)
                .offset(y: -cellSize * 0.62)

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.12, height: cellSize * 0.38)
                .offset(x: -cellSize * 0.18, y: -cellSize * 0.86)
                .rotationEffect(.degrees(-25))

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.12, height: cellSize * 0.38)
                .offset(x: cellSize * 0.18, y: -cellSize * 0.86)
                .rotationEffect(.degrees(25))

            Rectangle()
                .fill(lcdColor.opacity(0.88))
                .frame(width: cellSize * 0.16, height: cellSize * 0.16)
                .offset(x: -cellSize * 0.38, y: -cellSize * 0.22)

            Rectangle()
                .fill(lcdColor.opacity(0.88))
                .frame(width: cellSize * 0.16, height: cellSize * 0.16)
                .offset(x: cellSize * 0.38, y: -cellSize * 0.22)
        }
    }

    func bugPixel(cellSize: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.75, height: cellSize * 0.75)

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.42, height: cellSize * 0.34)
                .offset(y: -cellSize * 0.58)

            ForEach([-0.58, -0.34, 0.34, 0.58], id: \.self) { xOffset in
                Rectangle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: cellSize * 0.12, height: cellSize * 0.46)
                    .offset(x: cellSize * xOffset, y: cellSize * 0.08)
                    .rotationEffect(.degrees(xOffset < 0 ? -35 : 35))
            }

            Rectangle()
                .fill(lcdColor.opacity(0.88))
                .frame(width: cellSize * 0.16, height: cellSize * 0.16)
                .offset(x: -cellSize * 0.13, y: -cellSize * 0.1)

            Rectangle()
                .fill(lcdColor.opacity(0.88))
                .frame(width: cellSize * 0.16, height: cellSize * 0.16)
                .offset(x: cellSize * 0.13, y: -cellSize * 0.1)
        }
    }

    func caterpillarPixel(cellSize: CGFloat) -> some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: cellSize * 0.42, height: cellSize * 0.42)
                    .offset(x: CGFloat(index) * cellSize * 0.34 - cellSize * 0.5,
                            y: index % 2 == 0 ? -cellSize * 0.08 : cellSize * 0.08)
            }

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.36, height: cellSize * 0.36)
                .offset(x: cellSize * 0.96, y: -cellSize * 0.12)

            Rectangle()
                .fill(lcdColor.opacity(0.88))
                .frame(width: cellSize * 0.12, height: cellSize * 0.12)
                .offset(x: cellSize * 1.02, y: -cellSize * 0.18)
        }
    }

    func spiderPixel(cellSize: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.58, height: cellSize * 0.58)

            Rectangle()
                .fill(Color.black.opacity(0.82))
                .frame(width: cellSize * 0.36, height: cellSize * 0.34)
                .offset(y: -cellSize * 0.44)

            ForEach([-0.7, -0.48, 0.48, 0.7], id: \.self) { xOffset in
                Rectangle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: cellSize * 0.1, height: cellSize * 0.5)
                    .offset(x: cellSize * xOffset, y: -cellSize * 0.05)
                    .rotationEffect(.degrees(xOffset < 0 ? 55 : -55))

                Rectangle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: cellSize * 0.1, height: cellSize * 0.5)
                    .offset(x: cellSize * xOffset, y: cellSize * 0.25)
                    .rotationEffect(.degrees(xOffset < 0 ? -55 : 55))
            }

            Rectangle()
                .fill(lcdColor.opacity(0.88))
                .frame(width: cellSize * 0.12, height: cellSize * 0.12)
                .offset(x: -cellSize * 0.12, y: -cellSize * 0.45)

            Rectangle()
                .fill(lcdColor.opacity(0.88))
                .frame(width: cellSize * 0.12, height: cellSize * 0.12)
                .offset(x: cellSize * 0.12, y: -cellSize * 0.45)
        }
    }

    func scorpionPixel(cellSize: CGFloat) -> some View {
        ZStack {
            let dark = Color.black.opacity(0.90)
            let danger = Color.red.opacity(0.96)

            // Clear compact body.
            Rectangle()
                .fill(dark)
                .frame(width: cellSize * 0.58, height: cellSize * 0.50)

            // Head facing right.
            Rectangle()
                .fill(dark)
                .frame(width: cellSize * 0.34, height: cellSize * 0.34)
                .offset(x: cellSize * 0.42)

            // Two readable front claws.
            Rectangle()
                .fill(dark)
                .frame(width: cellSize * 0.34, height: cellSize * 0.14)
                .offset(x: cellSize * 0.70, y: -cellSize * 0.30)
                .rotationEffect(.degrees(-30))

            Rectangle()
                .fill(dark)
                .frame(width: cellSize * 0.34, height: cellSize * 0.14)
                .offset(x: cellSize * 0.70, y: cellSize * 0.30)
                .rotationEffect(.degrees(30))

            Rectangle()
                .fill(dark)
                .frame(width: cellSize * 0.18, height: cellSize * 0.18)
                .offset(x: cellSize * 0.88, y: -cellSize * 0.42)

            Rectangle()
                .fill(dark)
                .frame(width: cellSize * 0.18, height: cellSize * 0.18)
                .offset(x: cellSize * 0.88, y: cellSize * 0.42)

            // Raised tail, simpler and closer to the body.
            Rectangle()
                .fill(dark)
                .frame(width: cellSize * 0.16, height: cellSize * 0.36)
                .offset(x: -cellSize * 0.36, y: -cellSize * 0.26)

            Rectangle()
                .fill(dark)
                .frame(width: cellSize * 0.16, height: cellSize * 0.34)
                .offset(x: -cellSize * 0.22, y: -cellSize * 0.52)
                .rotationEffect(.degrees(-28))

            Rectangle()
                .fill(dark)
                .frame(width: cellSize * 0.16, height: cellSize * 0.30)
                .offset(x: cellSize * 0.02, y: -cellSize * 0.64)
                .rotationEffect(.degrees(-55))

            // Red stinger attached to the end of the tail.
            Rectangle()
                .fill(danger)
                .frame(width: cellSize * 0.16, height: cellSize * 0.16)
                .offset(x: cellSize * 0.18, y: -cellSize * 0.66)

            // Four chunky legs only.
            ForEach([-0.24, 0.24], id: \.self) { xOffset in
                Rectangle()
                    .fill(dark)
                    .frame(width: cellSize * 0.10, height: cellSize * 0.34)
                    .offset(x: cellSize * xOffset, y: cellSize * 0.38)
                    .rotationEffect(.degrees(xOffset < 0 ? -35 : 35))

                Rectangle()
                    .fill(dark)
                    .frame(width: cellSize * 0.10, height: cellSize * 0.34)
                    .offset(x: cellSize * xOffset, y: -cellSize * 0.38)
                    .rotationEffect(.degrees(xOffset < 0 ? 35 : -35))
            }

            // Red eye accent.
            Rectangle()
                .fill(danger)
                .frame(width: cellSize * 0.08, height: cellSize * 0.08)
                .offset(x: cellSize * 0.44, y: -cellSize * 0.05)
        }
        .scaleEffect(1.06)
    }

    func speedPillPixel(at point: Point, cellSize: CGFloat, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        let pillWidth = cellSize * 1.16
        let pillHeight = cellSize * 0.56

        return ZStack {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: pillWidth / 2, height: pillHeight)

                Rectangle()
                    .fill(Color.blue)
                    .frame(width: pillWidth / 2, height: pillHeight)
            }
            .frame(width: pillWidth, height: pillHeight)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.78), lineWidth: max(1, cellSize * 0.08))
            )

            Rectangle()
                .fill(Color.black.opacity(0.65))
                .frame(width: max(1, cellSize * 0.06), height: pillHeight * 0.86)
        }
        .position(pixelPosition(for: point, cellWidth: cellWidth, cellHeight: cellHeight))
    }

    var currentPlayerPillTutorialKey: String {
        let playerName = currentPlayerName.isEmpty ? "PLAYER" : currentPlayerName
        return "Y2KSnakePillTutorialSeen_\(playerName)_\(selectedMode.rawValue)"
    }

    func preparePillTutorialForNewGame() {
        shouldUsePillTutorialThisGame = !UserDefaults.standard.bool(forKey: currentPlayerPillTutorialKey)

        if shouldUsePillTutorialThisGame {
            UserDefaults.standard.set(true, forKey: currentPlayerPillTutorialKey)
        }
    }

    func activateRandomPillEffect() {
        let effectSessionID = gameSessionID
        let nextEffect = nextPillEffect()
        lastPillEffect = nextEffect
        activePillEffect = nextEffect
        speedPillActive = true
        speedPillSecondsLeft = 10
        speedPillEndTime = Date().addingTimeInterval(10.0)
        speedPillPulseScale = 1.0
        speedPillFlickerOpacity = 1.0

        switch nextEffect {
        case .speed:
            bonusOverlayText = "SPEED"
            playControlHaptic()
            startSpeedPillPulse()

        case .slow:
            bonusOverlayText = "SLOW"
            playControlHaptic()

        case .invert:
            bonusOverlayText = "INVERT"
            playControlHaptic()

        case .rainbow:
            bonusOverlayText = "RAINBOW"
            playControlHaptic()

        case .flicker:
            bonusOverlayText = "GLITCH"
            playControlHaptic()

        case .scoreBonus:
            score += 5
            bonusOverlayText = "+5 SCORE"
            playSuperFoodHaptic()
            updateLevel()
            resetPillEffect()

        case .scoreJackpot:
            score += 20
            bonusOverlayText = "+20 SCORE"
            jackpotOverlayKind = "score"
            playSuperFoodHaptic()
            updateLevel()
            canMove = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                guard gameSessionID == effectSessionID else { return }
                jackpotOverlayKind = nil

                DispatchQueue.main.asyncAfter(deadline: .now() + postLevelUpPauseDuration) {
                    guard gameSessionID == effectSessionID else { return }
                    lastMoveTime = Date()
                    canMove = true
                }
            }

            resetPillEffect()

        case .none:
            break
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard gameSessionID == effectSessionID else { return }
            bonusOverlayText = nil
        }
    }

    func nextPillEffect() -> PillEffect {
        pillPickupCount += 1

        // Tutorial pills happen only once per player per mode.
        if shouldUsePillTutorialThisGame {
            if pillPickupCount == 1 {
                return .rainbow
            }

            if pillPickupCount == 2 {
                return .scoreBonus
            }
        }

        let scoreJackpotChance: Int

        switch selectedMode {
        case .deathRace:
            scoreJackpotChance = 220
        case .speedRun:
            scoreJackpotChance = 180
        case .classic:
            scoreJackpotChance = 90
        case .labyrinth:
            scoreJackpotChance = 110
        }

        if Int.random(in: 1...scoreJackpotChance) == 1 {
            return .scoreJackpot
        }

        // Rare score bonus. More common in Speed Run.
        let scoreBonusChance = selectedMode == .speedRun ? 4 : 40
        if Int.random(in: 1...scoreBonusChance) == 1 {
            return .scoreBonus
        }

        let regularEffects: [PillEffect] = [
            .speed,
            .rainbow,
            .slow,
            .invert,
            .flicker
        ]

        let availableEffects = regularEffects.filter { $0 != lastPillEffect }
        return availableEffects.randomElement() ?? regularEffects.randomElement() ?? .speed
    }

    func resetPillEffect() {
        speedPillActive = false
        activePillEffect = .none
        speedPillSecondsLeft = 0
        pausedPillEffectRemainingTime = nil
        pausedSuperFoodRemainingTime = nil
        pausedMazeFoodRemainingTime = nil
        pausedSpeedPillRemainingTime = nil
        speedPillPulseScale = 1.0
        speedPillFlickerOpacity = 1.0
    }

    func clearSuperFood() {
        superFoodVisible = false
        superFood = nil
        superFoodBlinkFrame = 0
    }

    func clearSpeedPill() {
        speedPillVisible = false
        speedPill = nil
        speedPillBlinkFrame = 0
    }

    func clearBonusItems() {
        clearSuperFood()
        clearSpeedPill()
        resetPillEffect()
    }

    func pauseGameForAppLifecycle() {
        SoundManager.shared.pauseAllAudioForAppLifecycle()
        guard screen == .playing else { return }

        if legendMessageText != nil, countdownEndTime == nil, !canMove {
            legendMessageText = nil
            pausedCountdownRemainingTime = 3.1
            countdownToken += 1
        }
        pausePillEffectTimer()
        pauseCountdownTimer()
        pauseTimedRunTimer()
        pauseMultiplayerVSTimer()
        screen = .paused
        canMove = false
    }

    func pausePillEffectTimer() {
        if activePillEffect != .none {
            pausedPillEffectRemainingTime = max(0, speedPillEndTime.timeIntervalSince(Date()))
        }

        if superFoodVisible {
            let elapsed = Date().timeIntervalSince(superFoodSpawnTime)
            pausedSuperFoodRemainingTime = max(0, superFoodDuration - elapsed)
        }

        if selectedMode == .labyrinth {
            let elapsed = Date().timeIntervalSince(mazeFoodSpawnTime)
            pausedMazeFoodRemainingTime = max(0, mazeFoodDuration - elapsed)
        }

        if speedPillVisible {
            let elapsed = Date().timeIntervalSince(speedPillSpawnTime)
            pausedSpeedPillRemainingTime = max(0, speedPillDuration - elapsed)
        }
    }

    func resumePillEffectTimer() {
        if activePillEffect != .none,
           let remainingTime = pausedPillEffectRemainingTime {
            speedPillEndTime = Date().addingTimeInterval(remainingTime)
            speedPillSecondsLeft = max(0, Int(ceil(remainingTime)))
            pausedPillEffectRemainingTime = nil
        }

        if superFoodVisible,
           let remainingTime = pausedSuperFoodRemainingTime {
            superFoodSpawnTime = Date().addingTimeInterval(-(superFoodDuration - remainingTime))
            pausedSuperFoodRemainingTime = nil
        }

        if selectedMode == .labyrinth,
           let remainingTime = pausedMazeFoodRemainingTime {
            mazeFoodSpawnTime = Date().addingTimeInterval(-(mazeFoodDuration - remainingTime))
            pausedMazeFoodRemainingTime = nil
        }

        if speedPillVisible,
           let remainingTime = pausedSpeedPillRemainingTime {
            speedPillSpawnTime = Date().addingTimeInterval(-(speedPillDuration - remainingTime))
            pausedSpeedPillRemainingTime = nil
        }
    }

    func startSpeedPillPulse() {
        speedPillPulseScale = 1.0
        speedPillFlickerOpacity = 1.0

        withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
            speedPillPulseScale = 1.12
        }

        withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
            speedPillFlickerOpacity = 0.72
        }
    }

    var currentPlayerScorpionKey: String {
        "Y2KSnakeScorpionSeen_\(currentPlayerName.isEmpty ? "PLAYER" : currentPlayerName)"
    }

    func hasCurrentPlayerSeenScorpion() -> Bool {
        UserDefaults.standard.bool(forKey: currentPlayerScorpionKey)
    }

    func markCurrentPlayerScorpionSeen() {
        UserDefaults.standard.set(true, forKey: currentPlayerScorpionKey)
    }

    func startMultiplayerVSClassicMatch(difficulty: AIDifficulty? = nil) {
        SoundManager.shared.stopMenuMusic()
        gameSessionID = UUID()
        selectedMode = .classic
        isMultiplayerVSMatch = true
        if let difficulty {
            selectedVSAIDifficulty = difficulty
        }
        score = 0
        aiScore = 0
        lives = 3
        aiLives = 3
        level = 1
        multiplayerVSTimeLeft = 300
        pausedMultiplayerVSRemainingTime = nil
        newRecordAchieved = false
        digestionBumps.removeAll()
        queuedDirections.removeAll()
        canMove = false
        isRespawning = false
        snakeVisible = true
        multiplayerPlayerVisible = true
        multiplayerAIVisible = true
        aiTargetFood = nil
        aiFoodReactionMovesRemaining = 0
        aiDangerReactionMovesRemaining = 0
        aiDangerAheadLastTick = false
        bonusOverlayText = nil
        jackpotOverlayKind = nil
        countdownText = nil
        legendMessageText = nil
        walls.removeAll()
        clearBonusItems()
        resetMultiplayerVSSnakes()
        spawnMultiplayerVSFood()
        screen = .playing
        startCountdown()
    }

    func resetMultiplayerVSSnakes() {
        snake = [
            Point(x: 5, y: 3),
            Point(x: 5, y: 2),
            Point(x: 5, y: 1),
            Point(x: 5, y: 0)
        ]
        direction = .down
        nextDirection = .down
        queuedDirections.removeAll()

        aiSnake = [
            Point(x: columns - 6, y: rows - 4),
            Point(x: columns - 6, y: rows - 3),
            Point(x: columns - 6, y: rows - 2),
            Point(x: columns - 6, y: rows - 1)
        ]
        aiDirection = .up
        aiNextDirection = .up
        aiDangerReactionMovesRemaining = 0
        aiDangerAheadLastTick = false
        multiplayerPlayerVisible = true
        multiplayerAIVisible = true
    }

    func moveMultiplayerVSMatch() {
        applyQueuedPlayerDirection()
        direction = nextDirection
        aiNextDirection = chooseMultiplayerVSAIDirection()
        aiDirection = aiNextDirection

        guard let playerHead = snake.first, let currentAIHead = aiSnake.first else { return }

        let newPlayerHead = wrappedPoint(from: playerHead, moving: direction)
        let newAIHead = wrappedPoint(from: currentAIHead, moving: aiDirection)
        let playerWillGrow = newPlayerHead == food
        let aiWillGrow = newAIHead == food
        let playerCollisionBody = Set(playerWillGrow ? snake : Array(snake.dropLast()))
        let aiCollisionBody = Set(aiWillGrow ? aiSnake : Array(aiSnake.dropLast()))
        let sharedDestinationHeadToHead = newPlayerHead == newAIHead
        let directSwapHeadToHead = newPlayerHead == currentAIHead && newAIHead == playerHead
        let mutualHeadToHead = sharedDestinationHeadToHead || directSwapHeadToHead

        let playerDied = mutualHeadToHead || playerCollisionBody.contains(newPlayerHead) || aiCollisionBody.contains(newPlayerHead)
        let aiDied = mutualHeadToHead || aiCollisionBody.contains(newAIHead) || playerCollisionBody.contains(newAIHead)

        if playerDied || aiDied {
            resolveMultiplayerVSDeath(playerDied: playerDied, aiDied: aiDied)
            return
        }

        snake.insert(newPlayerHead, at: 0)
        aiSnake.insert(newAIHead, at: 0)

        if playerWillGrow {
            score += 1
            SoundManager.shared.playFood()
            playFoodHaptic()
        } else {
            snake.removeLast()
        }

        if aiWillGrow {
            aiScore += 1
        } else {
            aiSnake.removeLast()
        }

        if playerWillGrow || aiWillGrow {
            spawnMultiplayerVSFood()
        }
    }

    func applyQueuedPlayerDirection() {
        while !queuedDirections.isEmpty {
            let queuedDirection = queuedDirections.removeFirst()
            if !isOppositeDirection(direction, queuedDirection) {
                nextDirection = queuedDirection
                break
            }
        }
    }

    func chooseMultiplayerVSAIDirection() -> Direction {
        let riskDistance = aiRiskDistance()
        if let delayedDirection = aiDangerReactionDelayDirection(riskDistance: riskDistance) {
            return delayedDirection
        }

        let targetFood = aiShouldTargetFoodThisTick()
        let wantsRisk = Double.random(in: 0..<1) < aiRiskRatio()
        let candidates = availableAIDirections()
        let safeCandidates = candidates.filter { !isAIDirectionImmediatelyDeadly($0) }
        guard !safeCandidates.isEmpty else { return aiDirection }

        let cautiousCandidates = safeCandidates.filter { !isAIDirectionRisky($0, lookahead: riskDistance) }
        let evaluatedCandidates = (!wantsRisk && !cautiousCandidates.isEmpty) ? cautiousCandidates : safeCandidates

        if !targetFood, evaluatedCandidates.contains(aiDirection), !isAIDirectionRisky(aiDirection, lookahead: riskDistance) {
            return aiDirection
        }

        return evaluatedCandidates.min { first, second in
            aiDirectionScore(first, targetFood: targetFood, riskDistance: riskDistance) <
                aiDirectionScore(second, targetFood: targetFood, riskDistance: riskDistance)
        } ?? aiDirection
    }

    func aiRiskDistance() -> Int {
        switch selectedVSAIDifficulty {
        case .easy:
            return Bool.random() ? 4 : 5
        case .normal:
            return Bool.random() ? 2 : 3
        case .hard:
            return 1
        }
    }

    func aiRiskRatio() -> Double {
        switch selectedVSAIDifficulty {
        case .easy:
            return 0.10
        case .normal:
            return 0.30
        case .hard:
            return 0.50
        }
    }

    func aiShouldTargetFoodThisTick() -> Bool {
        if aiTargetFood != food {
            aiTargetFood = food
        }

        if aiFoodReactionMovesRemaining > 0 {
            aiFoodReactionMovesRemaining -= 1
            return false
        }

        return true
    }

    func scheduleAIReactionDelayForNewFood() {
        aiTargetFood = nil

        switch selectedVSAIDifficulty {
        case .easy:
            aiFoodReactionMovesRemaining = Int.random(in: 3...5)
        case .normal:
            aiFoodReactionMovesRemaining = Int.random(in: 1...2)
        case .hard:
            aiFoodReactionMovesRemaining = 0
        }
    }

    func aiDangerReactionDelayDirection(riskDistance: Int) -> Direction? {
        guard selectedVSAIDifficulty != .hard else {
            aiDangerReactionMovesRemaining = 0
            aiDangerAheadLastTick = false
            return nil
        }

        let dangerAhead = isAIDirectionRisky(aiDirection, lookahead: riskDistance)
        guard dangerAhead else {
            aiDangerReactionMovesRemaining = 0
            aiDangerAheadLastTick = false
            return nil
        }

        if aiDangerReactionMovesRemaining > 0 {
            aiDangerReactionMovesRemaining -= 1
            aiDangerAheadLastTick = true
            return aiDirection
        }

        guard !aiDangerAheadLastTick, !isAIDirectionImmediatelyDeadly(aiDirection) else {
            aiDangerAheadLastTick = true
            return nil
        }

        if Double.random(in: 0..<1) < aiDangerReactionDelayChance() {
            aiDangerReactionMovesRemaining = aiDangerReactionDelayMoves()
            if aiDangerReactionMovesRemaining > 0 {
                aiDangerReactionMovesRemaining -= 1
            }
            aiDangerAheadLastTick = true
            return aiDirection
        }

        aiDangerAheadLastTick = true
        return nil
    }

    func aiDangerReactionDelayChance() -> Double {
        switch selectedVSAIDifficulty {
        case .easy:
            return 0.50
        case .normal:
            return 0.20
        case .hard:
            return 0
        }
    }

    func aiDangerReactionDelayMoves() -> Int {
        switch selectedVSAIDifficulty {
        case .easy:
            return Int.random(in: 3...5)
        case .normal:
            return Int.random(in: 1...2)
        case .hard:
            return 0
        }
    }

    func aiDirectionScore(_ moveDirection: Direction, targetFood: Bool, riskDistance: Int) -> Int {
        guard let head = aiSnake.first else { return Int.max }

        let nextPoint = wrappedPoint(from: head, moving: moveDirection)
        var score = 0

        if targetFood {
            score += wrappedDistance(from: nextPoint, to: food) * 10
        } else {
            score += moveDirection == aiDirection ? -18 : 10
        }

        score -= freeNeighborCount(around: nextPoint) * aiFreeSpaceWeight()

        if isAIDirectionRisky(moveDirection, lookahead: riskDistance) {
            score += aiRiskPenalty()
        }

        score += aiHeadRiskPenalty(for: nextPoint)

        return score
    }

    func aiFreeSpaceWeight() -> Int {
        switch selectedVSAIDifficulty {
        case .easy:
            return 9
        case .normal:
            return 7
        case .hard:
            return 5
        }
    }

    func aiRiskPenalty() -> Int {
        switch selectedVSAIDifficulty {
        case .easy:
            return 70
        case .normal:
            return 42
        case .hard:
            return 16
        }
    }

    func aiHeadRiskPenalty(for point: Point) -> Int {
        guard let playerHead = snake.first else { return 0 }
        let projectedPlayerHead = wrappedPoint(from: playerHead, moving: direction)
        let distanceToProjectedHead = wrappedDistance(from: point, to: projectedPlayerHead)
        let distanceToCurrentHead = wrappedDistance(from: point, to: playerHead)

        switch selectedVSAIDifficulty {
        case .easy:
            return (distanceToProjectedHead <= 1 || distanceToCurrentHead <= 1) ? 90 : 0
        case .normal:
            return (distanceToProjectedHead <= 1 || distanceToCurrentHead <= 1) ? 55 : 0
        case .hard:
            return distanceToProjectedHead == 1 ? 18 : 0
        }
    }

    func availableAIDirections() -> [Direction] {
        [.up, .down, .left, .right].filter { !isOppositeDirection(aiDirection, $0) }
    }

    func isAIDirectionImmediatelyDeadly(_ moveDirection: Direction) -> Bool {
        guard let head = aiSnake.first else { return false }
        let nextPoint = wrappedPoint(from: head, moving: moveDirection)
        let aiBody = Set(Array(aiSnake.dropLast()))
        let playerBody = Set(snake)
        let projectedPlayerHead = snake.first.map { wrappedPoint(from: $0, moving: direction) }

        return aiBody.contains(nextPoint)
            || playerBody.contains(nextPoint)
            || projectedPlayerHead == nextPoint
    }

    func isAIDirectionRisky(_ moveDirection: Direction, lookahead: Int) -> Bool {
        guard var projectedPoint = aiSnake.first else { return false }
        let dangerCells = Set(aiSnake).union(Set(snake))

        for _ in 0..<lookahead {
            projectedPoint = wrappedPoint(from: projectedPoint, moving: moveDirection)
            if dangerCells.contains(projectedPoint) {
                return true
            }
        }

        return false
    }

    func freeNeighborCount(around point: Point) -> Int {
        let dangerCells = Set(aiSnake).union(Set(snake))
        let directions: [Direction] = [.up, .down, .left, .right]
        return directions.reduce(0) { count, moveDirection in
            let neighbor = wrappedPoint(from: point, moving: moveDirection)
            return count + (dangerCells.contains(neighbor) ? 0 : 1)
        }
    }

    func wrappedDistance(from first: Point, to second: Point) -> Int {
        let dx = abs(first.x - second.x)
        let dy = abs(first.y - second.y)
        return min(dx, columns - dx) + min(dy, rows - dy)
    }

    func resolveMultiplayerVSDeath(playerDied: Bool, aiDied: Bool) {
        guard !isRespawning else { return }

        if playerDied { lives -= 1 }
        if aiDied { aiLives -= 1 }

        pauseMultiplayerVSTimer()
        canMove = false
        isRespawning = true
        let sessionID = gameSessionID
        let matchIsOver = lives <= 0 || aiLives <= 0

        if matchIsOver {
            let result = determineMultiplayerVSResult()
            if result == .playerWins {
                SoundManager.shared.playWin()
            } else {
                SoundManager.shared.playGameOver()
            }
            playHitHaptic()
            blinkMultiplayerVSSnakes(times: 3, playerDied: playerDied, aiDied: aiDied)

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                guard gameSessionID == sessionID else { return }
                finishMultiplayerVSMatch(result: result, playSound: false)
            }
            return
        }

        SoundManager.shared.playLoseLife()
        playHitHaptic()
        blinkMultiplayerVSSnakes(times: 6, playerDied: playerDied, aiDied: aiDied)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard gameSessionID == sessionID else { return }
            resetMultiplayerVSSnakes()
            spawnMultiplayerVSFood()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard gameSessionID == sessionID else { return }
                resumeMultiplayerVSTimerIfNeeded()
                lastMoveTime = Date()
                isRespawning = false
                canMove = true
            }
        }
    }

    func blinkMultiplayerVSSnakes(times: Int, playerDied: Bool, aiDied: Bool) {
        let blinkSessionID = gameSessionID

        for i in 0..<times {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.45) {
                guard gameSessionID == blinkSessionID else { return }
                if playerDied { multiplayerPlayerVisible.toggle() }
                if aiDied { multiplayerAIVisible.toggle() }
            }
        }
    }

    func updateMultiplayerVSTimer() {
        guard isMultiplayerVSMatch else { return }

        let elapsed = Date().timeIntervalSince(multiplayerVSStartTime)
        multiplayerVSTimeLeft = max(0, Int(ceil(300.0 - elapsed)))

        if multiplayerVSTimeLeft <= 0 {
            finishMultiplayerVSMatch(result: determineMultiplayerVSResult())
        }
    }

    func finishMultiplayerVSMatch(result: MultiplayerVSResult, playSound: Bool = true) {
        if playSound {
            if result == .playerWins {
                SoundManager.shared.playWin()
            } else {
                SoundManager.shared.playGameOver()
            }
        }
        multiplayerVSResult = result
        canMove = false
        isRespawning = false
        multiplayerPlayerVisible = true
        multiplayerAIVisible = true
        screen = .multiplayerVSResult
    }

    func determineMultiplayerVSResult() -> MultiplayerVSResult {
        if lives <= 0 && aiLives <= 0 {
            return compareMultiplayerVSScoreLivesAndLength()
        }
        if lives <= 0 { return .aiWins }
        if aiLives <= 0 { return .playerWins }
        return compareMultiplayerVSScoreLivesAndLength()
    }

    func compareMultiplayerVSScoreLivesAndLength() -> MultiplayerVSResult {
        if score != aiScore {
            return score > aiScore ? .playerWins : .aiWins
        }
        if lives != aiLives {
            return lives > aiLives ? .playerWins : .aiWins
        }
        if snake.count != aiSnake.count {
            return snake.count > aiSnake.count ? .playerWins : .aiWins
        }
        return .draw
    }

    func spawnMultiplayerVSFood() {
        let blockedCells = Set(snake).union(Set(aiSnake))
        var newFood: Point

        repeat {
            newFood = Point(
                x: Int.random(in: 0..<columns),
                y: Int.random(in: 0..<rows)
            )
        } while blockedCells.contains(newFood)

        food = newFood
        scheduleAIReactionDelayForNewFood()
    }

    func finishMultiplayerVSMenuReturn() {
        isMultiplayerVSMatch = false
        canMove = false
        isRespawning = false
        countdownText = nil
        pausedMultiplayerVSRemainingTime = nil
        screen = .multiplayerVSMainMenu
        SoundManager.shared.playMenuMusic()
    }

    func moveSnake() {
        while !queuedDirections.isEmpty {
            let queuedDirection = queuedDirections.removeFirst()

            if protectNextMoveAfterRespawn && wouldCollideOnNextStep(moving: queuedDirection) {
                continue
            }

            if !isOppositeDirection(direction, queuedDirection) {
                nextDirection = queuedDirection
                break
            }
        }

        direction = nextDirection
        protectNextMoveAfterRespawn = false

        guard let head = snake.first else { return }
        var newHead = head

        switch direction {
        case .up:
            newHead = Point(x: head.x, y: head.y - 1)
        case .down:
            newHead = Point(x: head.x, y: head.y + 1)
        case .left:
            newHead = Point(x: head.x - 1, y: head.y)
        case .right:
            newHead = Point(x: head.x + 1, y: head.y)
        }

        if newHead.x < 0 {
            newHead = Point(x: columns - 1, y: newHead.y)
        } else if newHead.x >= columns {
            newHead = Point(x: 0, y: newHead.y)
        }

        if newHead.y < 0 {
            newHead = Point(x: newHead.x, y: rows - 1)
        } else if newHead.y >= rows {
            newHead = Point(x: newHead.x, y: 0)
        }

        if snake.contains(newHead) || walls.contains(newHead) {
            loseLife()
            return
        }

        snake.insert(newHead, at: 0)

        if newHead == food {
            SoundManager.shared.playFood()
            playFoodHaptic()
            score += 1
            if selectedMode == .deathRace {
                speedRunFoodCount += 1
            }
            let previousLevel = level
            updateLevel()
            let didRegenerateMazeWalls = selectedMode == .labyrinth && level > previousLevel
            digestionBumps[newHead] = 14
            if score > highScore {
                highScore = score
                UserDefaults.standard.set(highScore, forKey: "HighScore")
            }

            if isClassicWin() {
                addScoreToLeaderboard()
                SoundManager.shared.playWin()
                screen = .gameWon
                canMove = false
                superFoodVisible = false
                superFood = nil
                return
            }

            if !didRegenerateMazeWalls {
                if superFoodVisible {
                    food = Point(x: -1, y: -1)
                } else if selectedMode == .labyrinth {
                    food = Point(x: -1, y: -1)
                    scheduleMazeItemRespawn()
                } else {
                    spawnFood()
                    maybeSpawnSuperFood()
                    maybeSpawnSpeedPill()
                }
            }
        } else if superFoodVisible, newHead == superFood {
            if superFoodType == .scorpion {
                superFoodVisible = false
                superFood = nil
                superFoodBlinkFrame = 0

                let isFirstScorpionForPlayer = !hasCurrentPlayerSeenScorpion()
                markCurrentPlayerScorpionSeen()

                if isFirstScorpionForPlayer || Bool.random() {
                    SoundManager.shared.playScorpionGood()
                    playExtraLifeHaptic()

                    if selectedMode == .speedRun {
                        timedRunSecondsLeft += 20
                        timedRunStartTime = timedRunStartTime.addingTimeInterval(20)
                        bonusOverlayText = "+20 SEC"
                        jackpotOverlayKind = "time"
                    } else {
                        lives += 1
                        bonusOverlayText = "+1 LIFE"
                        jackpotOverlayKind = "life"
                    }

                    digestionBumps[newHead] = 24

                    canMove = false
                    let scorpionSessionID = gameSessionID
                    let jackpotOverlayDuration = 1.4

                    DispatchQueue.main.asyncAfter(deadline: .now() + jackpotOverlayDuration) {
                        guard gameSessionID == scorpionSessionID else { return }
                        jackpotOverlayKind = nil

                        DispatchQueue.main.asyncAfter(deadline: .now() + postLevelUpPauseDuration) {
                            guard gameSessionID == scorpionSessionID else { return }
                            lastMoveTime = Date()
                            canMove = true
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        guard gameSessionID == scorpionSessionID else { return }
                        bonusOverlayText = nil
                    }
                } else {
                    snake.removeLast()
                    loseLife()
                    return
                }
            } else {
                SoundManager.shared.playSuperFood()
                playSuperFoodHaptic()
                score += 3
                superFoodVisible = false
                superFood = nil
                superFoodBlinkFrame = 0
                updateLevel()
                digestionBumps[newHead] = 18
            }

            if food.x < 0 || food.y < 0 {
                let reachableCells: Set<Point>? = selectedMode == .labyrinth ? reachableCellsFromSnakeHead() : nil
                spawnFood(reachableCells: reachableCells)
                maybeSpawnSuperFood(reachableCells: reachableCells)
                maybeSpawnSpeedPill(reachableCells: reachableCells)
            }
        } else if speedPillVisible, newHead == speedPill {
            speedPillVisible = false
            speedPill = nil
            speedPillBlinkFrame = 0
            SoundManager.shared.playPillPickup()
            activateRandomPillEffect()
            snake.removeLast()
        } else {
            snake.removeLast()
        }
        updateDigestionBumps()
    }

    func updateDigestionBumps() {
        for point in digestionBumps.keys {
            if let remainingMoves = digestionBumps[point] {
                if remainingMoves <= 1 || !snake.contains(point) {
                    digestionBumps.removeValue(forKey: point)
                } else {
                    digestionBumps[point] = remainingMoves - 1
                }
            }
        }
    }

    func scheduleMazeItemRespawn() {
        let respawnSessionID = gameSessionID

        DispatchQueue.main.async {
            guard gameSessionID == respawnSessionID else { return }
            guard selectedMode == .labyrinth else { return }

            let reachableCells = reachableCellsFromSnakeHead()
            spawnFood(reachableCells: reachableCells)
            maybeSpawnSuperFood(reachableCells: reachableCells)
            maybeSpawnSpeedPill(reachableCells: reachableCells)
        }
    }

    func isClassicWin() -> Bool {
        selectedMode == .classic && snake.count >= columns * rows
    }

    func updateLevel() {
        guard selectedMode != .classic && selectedMode != .speedRun else {
            if selectedMode == .classic || selectedMode == .speedRun {
                level = 1
            }
            return
        }

        let pointsPerLevel: Int

        switch selectedMode {
        case .labyrinth:
            pointsPerLevel = 10
        case .deathRace:
            pointsPerLevel = 15
        default:
            pointsPerLevel = 10
        }

        let newLevel = score / pointsPerLevel + 1

        if newLevel > level {
            SoundManager.shared.playLevelUp()
            playLevelUpHaptic()
            level = newLevel
            if selectedMode == .labyrinth {
                food = Point(x: -1, y: -1)
                clearSuperFood()
                clearSpeedPill()
                generateMazeWalls()

                let reachableCells = reachableCellsFromSnakeHead()
                spawnFood(reachableCells: reachableCells)
                maybeSpawnSuperFood(reachableCells: reachableCells)
                maybeSpawnSpeedPill(reachableCells: reachableCells)
            }
            canMove = false
            let levelUpSessionID = gameSessionID

            DispatchQueue.main.asyncAfter(deadline: .now() + postLevelUpPauseDuration) {
                guard gameSessionID == levelUpSessionID else { return }
                guard jackpotOverlayKind == nil else { return }
                lastMoveTime = Date()
                canMove = true
            }
        }
    }

    func updateTimedSpeedRun() {
        guard selectedMode == .speedRun else { return }

        let elapsed = Int(Date().timeIntervalSince(timedRunStartTime))
        timedRunSecondsLeft = max(0, 60 - elapsed)

        if timedRunSecondsLeft <= 10 && timedRunSecondsLeft > 0 && timedRunSecondsLeft != lastFinalCountdownTickSecond {
            SoundManager.shared.playFinalCountdownTick()
            lastFinalCountdownTickSecond = timedRunSecondsLeft
        }

        if timedRunSecondsLeft <= 0 {
            startTimeUpSequence()
        }
    }

    func changeDirection(_ newDirection: Direction) -> Bool {
        guard screen == .playing else { return false }
        guard canMove else { return false }

        let currentInputDirection = queuedDirections.last ?? nextDirection

        guard !isOppositeDirection(currentInputDirection, newDirection) else {
            return false
        }

        guard currentInputDirection != newDirection else {
            return false
        }

        queuedDirections.append(newDirection)

        // Keep only a short buffer so controls feel responsive but not delayed.
        if queuedDirections.count > 3 {
            queuedDirections.removeFirst(queuedDirections.count - 3)
        }

        return true
    }

    func isOppositeDirection(_ first: Direction, _ second: Direction) -> Bool {
        switch (first, second) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return true
        default:
            return false
        }
    }

    func wouldCollideOnNextStep(moving moveDirection: Direction) -> Bool {
        guard let head = snake.first else { return false }
        let nextPoint = wrappedPoint(from: head, moving: moveDirection)
        return snake.contains(nextPoint) || walls.contains(nextPoint)
    }

    func neighbors(of point: Point) -> [Point] {
        let rawNeighbors = [
            Point(x: point.x, y: point.y - 1),
            Point(x: point.x, y: point.y + 1),
            Point(x: point.x - 1, y: point.y),
            Point(x: point.x + 1, y: point.y)
        ]

        return rawNeighbors.filter { neighbor in
            neighbor.x >= 0 && neighbor.x < columns && neighbor.y >= 0 && neighbor.y < rows
        }
    }

    func reachableCellsFromSnakeHead() -> Set<Point> {
        guard let head = snake.first else { return [] }

        var visited: Set<Point> = [head]
        var queue: [Point] = [head]
        let blockedCells = walls.union(Set(snake.dropFirst()))

        var queueIndex = 0

        while queueIndex < queue.count {
            let current = queue[queueIndex]
            queueIndex += 1

            for neighbor in neighbors(of: current) {
                guard !visited.contains(neighbor) else { continue }
                guard !blockedCells.contains(neighbor) else { continue }

                visited.insert(neighbor)
                queue.append(neighbor)
            }
        }

        return visited
    }

    func escapeAreaSize(from start: Point, avoiding blockedPoint: Point) -> Int {
        guard !walls.contains(start) else { return 0 }
        guard !snake.contains(start) else { return 0 }
        guard start != blockedPoint else { return 0 }

        var visited: Set<Point> = [start]
        var queue: [Point] = [start]
        var queueIndex = 0

        while queueIndex < queue.count {
            let current = queue[queueIndex]
            queueIndex += 1

            for neighbor in neighbors(of: current) {
                guard neighbor != blockedPoint else { continue }
                guard !visited.contains(neighbor) else { continue }
                guard !walls.contains(neighbor) else { continue }
                guard !snake.contains(neighbor) else { continue }

                visited.insert(neighbor)
                queue.append(neighbor)
            }
        }

        return visited.count
    }

    func isSafeMazeFoodCell(_ point: Point, reachableCells: Set<Point>) -> Bool {
        guard reachableCells.contains(point) else { return false }
        guard !walls.contains(point) else { return false }
        guard !snake.contains(point) else { return false }

        let freeNeighborCount = neighbors(of: point).filter { neighbor in
            !walls.contains(neighbor) && !snake.contains(neighbor)
        }.count

        return freeNeighborCount >= 2
    }

    func isSafeMazeSpawnCell(_ point: Point, reachableCells: Set<Point>) -> Bool {
        guard reachableCells.contains(point) else { return false }
        guard !walls.contains(point) else { return false }
        guard !snake.contains(point) else { return false }

        let freeNeighbors = neighbors(of: point).filter { neighbor in
            !walls.contains(neighbor) && !snake.contains(neighbor)
        }

        guard freeNeighbors.count >= 2 else { return false }

        // Avoid tiny dead-end pockets: after taking the food, the player should still
        // have enough open space to escape instead of being trapped by a one-way pocket.
        let bestEscapeArea = freeNeighbors
            .map { escapeAreaSize(from: $0, avoiding: point) }
            .max() ?? 0

        return bestEscapeArea >= 8
    }

    func randomSafeSpawnPoint(
        excluding extraBlockedCells: Set<Point> = [],
        reachableCells providedReachableCells: Set<Point>? = nil
    ) -> Point? {
        if selectedMode == .labyrinth {
            let reachableCells = providedReachableCells ?? reachableCellsFromSnakeHead()
            let shuffledReachableCells = reachableCells.shuffled()

            for point in shuffledReachableCells {
                guard !extraBlockedCells.contains(point) else { continue }
                guard !snake.contains(point) else { continue }
                guard !walls.contains(point) else { continue }
                return point
            }

            return nil
        }

        // Fast random attempts for non-maze modes.
        for _ in 0..<80 {
            let point = Point(
                x: Int.random(in: 0..<columns),
                y: Int.random(in: 0..<rows)
            )

            if !snake.contains(point) && !walls.contains(point) && !extraBlockedCells.contains(point) {
                return point
            }
        }

        // Fallback only if the board is extremely crowded.
        let availablePoints = (0..<rows).flatMap { y in
            (0..<columns).map { x in
                Point(x: x, y: y)
            }
        }.filter { point in
            !snake.contains(point) && !walls.contains(point) && !extraBlockedCells.contains(point)
        }

        return availablePoints.randomElement()
    }

    func isBonusSpawnCellClear(_ point: Point, extraBlockedCells: Set<Point>) -> Bool {
        guard point.x > 0 && point.x < columns - 1 else { return false }
        guard point.y > 0 && point.y < rows - 1 else { return false }
        guard !snake.contains(point) else { return false }
        guard !walls.contains(point) else { return false }
        guard !extraBlockedCells.contains(point) else { return false }

        for neighbor in neighbors(of: point) {
            if walls.contains(neighbor) || snake.contains(neighbor) || extraBlockedCells.contains(neighbor) {
                return false
            }
        }

        return true
    }

    func randomSafeBonusSpawnPoint(
        excluding extraBlockedCells: Set<Point> = [],
        reachableCells providedReachableCells: Set<Point>? = nil
    ) -> Point? {
        if selectedMode == .labyrinth {
            let reachableCells = providedReachableCells ?? reachableCellsFromSnakeHead()
            let shuffledReachableCells = reachableCells.shuffled()

            for point in shuffledReachableCells {
                guard isBonusSpawnCellClear(point, extraBlockedCells: extraBlockedCells) else { continue }
                return point
            }

            return nil
        }

        for _ in 0..<120 {
            let point = Point(
                x: Int.random(in: 1..<(columns - 1)),
                y: Int.random(in: 1..<(rows - 1))
            )

            if isBonusSpawnCellClear(point, extraBlockedCells: extraBlockedCells) {
                return point
            }
        }

        return nil
    }

    func spawnFood(reachableCells: Set<Point>? = nil) {
        let blockedCells = Set([superFood, speedPill].compactMap { $0 })

        if let safePoint = randomSafeSpawnPoint(excluding: blockedCells, reachableCells: reachableCells) {
            food = safePoint
            resetMazeFoodTimer()
            return
        }

        if selectedMode == .labyrinth {
            let reachableMazeCells = reachableCells ?? reachableCellsFromSnakeHead()
            let fallbackMazePoints = reachableMazeCells.filter { point in
                !snake.contains(point)
                && !walls.contains(point)
                && !blockedCells.contains(point)
            }

            if let fallbackPoint = fallbackMazePoints.randomElement() {
                food = fallbackPoint
                resetMazeFoodTimer()
                return
            }
        }

        // Fallback for extremely crowded non-maze boards.
        var newFood: Point
        repeat {
            newFood = Point(
                x: Int.random(in: 0..<columns),
                y: Int.random(in: 0..<rows)
            )
        } while snake.contains(newFood) || walls.contains(newFood) || (superFoodVisible && newFood == superFood) || (speedPillVisible && newFood == speedPill)

        food = newFood
        resetMazeFoodTimer()
    }

    func maybeSpawnSuperFood(reachableCells: Set<Point>? = nil) {
        guard !superFoodVisible else { return }
        if Int.random(in: 1...4) != 1 { return }

        let blockedCells = Set([food, speedPill].compactMap { $0 })
        guard let point = randomSafeBonusSpawnPoint(excluding: blockedCells, reachableCells: reachableCells) else { return }

        superFood = point
        let regularSuperFoods: [SuperFoodType] = [.butterfly, .bug, .caterpillar, .spider]
        // Scorpion is a very rare risky super food.
        if Int.random(in: 1...40) == 1 {
            superFoodType = lastSuperFoodType == .scorpion
                ? (regularSuperFoods.randomElement() ?? .butterfly)
                : .scorpion
        } else {
            superFoodType = regularSuperFoods.randomElement() ?? .butterfly
        }
        lastSuperFoodType = superFoodType
        superFoodSpawnTime = Date()
        superFoodBlinkFrame = 0
        superFoodVisible = true
        if superFoodType == .scorpion {
            SoundManager.shared.playScorpionSpawn()
        }
    }

    func maybeSpawnSpeedPill(reachableCells: Set<Point>? = nil) {
        if speedPillVisible || activePillEffect != .none { return }
        // Release logic: 20% chance normally, 25% in Speed Run.
        let spawnChance = selectedMode == .speedRun ? 4 : 5
        if Int.random(in: 1...spawnChance) != 1 { return }

        let blockedCells = Set([food, superFood].compactMap { $0 })
        guard let point = randomSafeBonusSpawnPoint(excluding: blockedCells, reachableCells: reachableCells) else { return }

        speedPill = point
        speedPillSpawnTime = Date()
        speedPillBlinkFrame = 0
        speedPillVisible = true
    }


    func updateSpeedPill() {
        if speedPillVisible {
            speedPillBlinkFrame += 1
        }

        if speedPillVisible && Date().timeIntervalSince(speedPillSpawnTime) >= speedPillDuration {
            speedPillVisible = false
            speedPill = nil
            speedPillBlinkFrame = 0
        }

        if activePillEffect != .none {
            speedPillSecondsLeft = max(0, Int(ceil(speedPillEndTime.timeIntervalSince(Date()))))

            if Date() >= speedPillEndTime {
                resetPillEffect()
            }
        }
    }

    func updateSuperFood() {
        guard superFoodVisible else { return }
        superFoodBlinkFrame += 1

        if Date().timeIntervalSince(superFoodSpawnTime) >= superFoodDuration {
            superFoodVisible = false
            superFood = nil
            superFoodBlinkFrame = 0
            if food.x < 0 || food.y < 0 {
                let reachableCells: Set<Point>? = selectedMode == .labyrinth ? reachableCellsFromSnakeHead() : nil
                spawnFood(reachableCells: reachableCells)
                maybeSpawnSuperFood(reachableCells: reachableCells)
                maybeSpawnSpeedPill(reachableCells: reachableCells)
            }
        }
    }

    func updateMazeFood() {
        guard selectedMode == .labyrinth else { return }
        guard screen == .playing else { return }
        guard canMove else { return }
        guard !isRespawning else { return }

        mazeFoodBlinkFrame += 1

        if Date().timeIntervalSince(mazeFoodSpawnTime) >= mazeFoodDuration {
            score = max(0, score - 1)
            let reachableCells = reachableCellsFromSnakeHead()
            spawnFood(reachableCells: reachableCells)
            maybeSpawnSuperFood(reachableCells: reachableCells)
            maybeSpawnSpeedPill(reachableCells: reachableCells)
        }
    }

    func generateMazeWalls() {
        walls.removeAll()
        guard selectedMode == .labyrinth else { return }

        let safeZone = makeSnakeSafeZone(radius: 3)

        // Maze level can grow above L5, but wall complexity is capped at L5.
        // After L5, every 10 points generates a fresh L5-style labyrinth.
        let mazeDifficulty = min(level, 5)
        let wallGroups = 1 + mazeDifficulty * 3
        let minWallLength = min(3 + mazeDifficulty, 7)
        let maxWallLength = min(5 + mazeDifficulty * 2, 13)

        for _ in 0..<wallGroups {
            let horizontal = Bool.random()
            let length = Int.random(in: minWallLength...maxWallLength)
            let startX = Int.random(in: 3..<(columns - 3))
            let startY = Int.random(in: 3..<(rows - 3))

            for offset in 0..<length {
                let point = horizontal
                    ? Point(x: min(startX + offset, columns - 3), y: startY)
                    : Point(x: startX, y: min(startY + offset, rows - 3))

                if !safeZone.contains(point) && !snake.contains(point) {
                    walls.insert(point)
                }
            }
        }

        addLongMazeWalls(safeZone: safeZone)
        addMazeCornerBlocks(safeZone: safeZone)
    }

    func fillUnreachableMazeCells() {
        guard selectedMode == .labyrinth else { return }

        let reachableCells = reachableCellsFromSnakeHead()

        for y in 0..<rows {
            for x in 0..<columns {
                let point = Point(x: x, y: y)

                guard !snake.contains(point) else { continue }
                guard !walls.contains(point) else { continue }

                if !reachableCells.contains(point) {
                    walls.insert(point)
                }
            }
        }
    }

    func makeSnakeSafeZone(radius: Int) -> Set<Point> {
        var safeZone = Set<Point>()

        for segment in snake {
            for xOffset in -radius...radius {
                for yOffset in -radius...radius {
                    let point = Point(
                        x: segment.x + xOffset,
                        y: segment.y + yOffset
                    )

                    if point.x >= 0 && point.x < columns && point.y >= 0 && point.y < rows {
                        safeZone.insert(point)
                    }
                }
            }
        }

        return safeZone
    }

    func addLongMazeWalls(safeZone: Set<Point>) {
        let mazeDifficulty = min(level, 5)
        guard mazeDifficulty >= 2 else { return }

        let longWallCount = mazeDifficulty - 1

        for _ in 0..<longWallCount {
            let horizontal = Bool.random()
            let length = Int.random(in: 8...min(10 + mazeDifficulty * 2, 18))
            let startX = Int.random(in: 3..<(columns - 3))
            let startY = Int.random(in: 4..<(rows - 4))

            for offset in 0..<length {
                let point = horizontal
                    ? Point(x: min(startX + offset, columns - 3), y: startY)
                    : Point(x: startX, y: min(startY + offset, rows - 3))

                if !safeZone.contains(point) && !snake.contains(point) {
                    walls.insert(point)
                }
            }
        }
    }

    func addMazeCornerBlocks(safeZone: Set<Point>) {
        let mazeDifficulty = min(level, 5)
        guard mazeDifficulty >= 3 else { return }

        let possibleCorners = [
            [Point(x: 5, y: 5), Point(x: 6, y: 5), Point(x: 5, y: 6)],
            [Point(x: 26, y: 5), Point(x: 25, y: 5), Point(x: 26, y: 6)],
            [Point(x: 5, y: 26), Point(x: 6, y: 26), Point(x: 5, y: 25)],
            [Point(x: 26, y: 26), Point(x: 25, y: 26), Point(x: 26, y: 25)]
        ]

        for corner in possibleCorners.shuffled().prefix(mazeDifficulty - 2) {
            for point in corner where !snake.contains(point) && !safeZone.contains(point) {
                walls.insert(point)
            }
        }
    }

    func loseLife() {
        guard !isRespawning else { return }

        lives -= 1

        if lives <= 0 || (selectedMode != .classic && selectedMode != .labyrinth) {
            startFinalDeathSequence()
            return
        }

        SoundManager.shared.playLoseLife()
        playHitHaptic()
        isRespawning = true
        canMove = false

        let respawnSessionID = gameSessionID

        blinkSnake(times: 6)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard gameSessionID == respawnSessionID else { return }

            respawnClassicSnakeKeepingLength()
            spawnFood()
            snakeVisible = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard gameSessionID == respawnSessionID else { return }

                lastMoveTime = Date()
                isRespawning = false
                canMove = true
            }
        }
    }

    func startTimeUpSequence() {
        guard !isRespawning else { return }

        addScoreToLeaderboard()
        SoundManager.shared.playWin()

        canMove = false
        isRespawning = true
        clearBonusItems()
        let timeUpSessionID = gameSessionID

        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index)) {
                guard gameSessionID == timeUpSessionID else { return }
                playHitHaptic()
                snakeVisible = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) + 0.35) {
                guard gameSessionID == timeUpSessionID else { return }
                snakeVisible = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard gameSessionID == timeUpSessionID else { return }
            snakeVisible = true
            isRespawning = false
            canMove = true
            screen = .timeUp
        }
    }

    func startFinalDeathSequence() {
        addScoreToLeaderboard()
        SoundManager.shared.playGameOver()

        canMove = false
        isRespawning = true
        clearSpeedPill()
        resetPillEffect()
        let deathSessionID = gameSessionID

        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index)) {
                guard gameSessionID == deathSessionID else { return }
                playHitHaptic()
                snakeVisible = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) + 0.35) {
                guard gameSessionID == deathSessionID else { return }
                snakeVisible = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard gameSessionID == deathSessionID else { return }
            snakeVisible = true
            isRespawning = false
            canMove = true
            screen = .gameOver
        }
    }

    func finishCurrentRunAndSaveScore() {
        guard score > 0 else { return }
        addScoreToLeaderboard()
    }

    func addScoreToLeaderboard() {
        let speedForRecord: Int? = (selectedMode == .classic || selectedMode == .labyrinth) ? selectedSpeed : nil
        var list = LeaderboardManager.load(for: selectedMode, speed: speedForRecord)

        let entry = ScoreEntry(
            playerName: currentPlayerName.isEmpty ? "PLAYER" : currentPlayerName,
            score: score
        )

        let previousList = list
        list.append(entry)
        list.sort { $0.score > $1.score }
        list = Array(list.prefix(5))

        newRecordAchieved = list.contains(entry) && !previousList.contains(entry)

        LeaderboardManager.save(list, for: selectedMode, speed: speedForRecord)
    }


    func blinkSnake(times: Int) {
        let blinkSessionID = gameSessionID

        for i in 0..<times {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.45) {
                guard gameSessionID == blinkSessionID else { return }
                snakeVisible.toggle()
            }
        }
    }

    func startNewGame() {
        SoundManager.shared.stopMenuMusic()
        gameSessionID = UUID()
        isMultiplayerVSMatch = false
        pausedMultiplayerVSRemainingTime = nil
        score = 0
        newRecordAchieved = false
        lives = (selectedMode == .classic || selectedMode == .labyrinth) ? 3 : 1
        level = 1
        speedRunFoodCount = 0
        timedRunSecondsLeft = 60
        timedRunStartTime = Date()
        lastFinalCountdownTickSecond = -1
        digestionBumps.removeAll()
        queuedDirections.removeAll()
        snakeVisible = true
        isRespawning = false
        canMove = false
        bonusOverlayText = nil
        jackpotOverlayKind = nil
        countdownText = nil
        legendMessageText = nil
        clearBonusItems()
        pillPickupCount = 0
        lastPillEffect = .none
        preparePillTutorialForNewGame()
        resetSnakePosition()
        generateMazeWalls()
        spawnFood()
        screen = .playing
        startLegendOrCountdown()
    }

    func playInitialBootSoundIfNeeded() {
        guard !didPlayBootSound else { return }
        didPlayBootSound = true
        SoundManager.shared.playRetroBoot()
    }

    func respawnClassicSnakeKeepingLength() {
        var path: [Point] = []
        var movingRight = true

        for y in 0..<rows {
            let xValues = movingRight ? Array(0..<columns) : Array((0..<columns).reversed())

            for x in xValues {
                let point = Point(x: x, y: y)
                if !walls.contains(point) {
                    path.append(point)
                }
            }

            movingRight.toggle()
        }

        let targetLength = min(max(snake.count, 4), path.count)
        let bodyPath = Array(path.prefix(targetLength))
        snake = Array(bodyPath.reversed())

        chooseSafeRespawnDirection()

        digestionBumps.removeAll()
        queuedDirections.removeAll()
        protectNextMoveAfterRespawn = true
        clearBonusItems()
    }

    func chooseSafeRespawnDirection() {
        guard let head = snake.first else {
            direction = .right
            nextDirection = .right
            queuedDirections.removeAll()
            return
        }

        // Prefer vertical movement first after respawn.
        // This avoids immediate self-collision when the snake length reaches board width.
        let preferredDirections: [Direction] = [.down, .up, .right, .left]

        for candidateDirection in preferredDirections {
            let nextPoint = wrappedPoint(from: head, moving: candidateDirection)
            if !snake.contains(nextPoint) && !walls.contains(nextPoint) {
                direction = candidateDirection
                nextDirection = candidateDirection
                return
            }
        }

        direction = .right
        nextDirection = .right
    }

    func wrappedPoint(from point: Point, moving moveDirection: Direction) -> Point {
        var newPoint = point

        switch moveDirection {
        case .up:
            newPoint = Point(x: point.x, y: point.y - 1)
        case .down:
            newPoint = Point(x: point.x, y: point.y + 1)
        case .left:
            newPoint = Point(x: point.x - 1, y: point.y)
        case .right:
            newPoint = Point(x: point.x + 1, y: point.y)
        }

        if newPoint.x < 0 {
            newPoint = Point(x: columns - 1, y: newPoint.y)
        } else if newPoint.x >= columns {
            newPoint = Point(x: 0, y: newPoint.y)
        }

        if newPoint.y < 0 {
            newPoint = Point(x: newPoint.x, y: rows - 1)
        } else if newPoint.y >= rows {
            newPoint = Point(x: newPoint.x, y: 0)
        }

        return newPoint
    }

    func resetSnakePosition() {
        snake = [
            Point(x: 10, y: 16),
            Point(x: 9, y: 16),
            Point(x: 8, y: 16),
            Point(x: 7, y: 16)
        ]
        if selectedMode == .classic || selectedMode == .speedRun || selectedMode == .deathRace {
            level = 1
        }
        speedRunFoodCount = 0
        digestionBumps.removeAll()
        queuedDirections.removeAll()
        clearBonusItems()
        if selectedMode != .labyrinth {
            walls.removeAll()
        }
        direction = .right
        nextDirection = .right
    }

    func deleteSelectedPlayer() {
        guard let player = playerToDelete else {
            screen = .playerManagement
            return
        }

        let deletedCurrentPlayer = currentPlayerName == player

        players.removeAll { $0 == player }
        UserDefaults.standard.set(players, forKey: "SnakePlayers")
        UserDefaults.standard.removeObject(forKey: ContentView.snakeSkinStorageKey(for: player))
        LeaderboardManager.removeScores(for: player)

        if deletedCurrentPlayer {
            currentPlayerName = ""
            selectedSnakeSkin = .black
            UserDefaults.standard.removeObject(forKey: "CurrentSnakePlayer")
        }

        selectedPlayerForAction = nil
        playerToDelete = nil

        if players.isEmpty {
            newPlayerName = ""
            screen = .newPlayer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isNewPlayerNameFocused = true
            }
        } else {
            screen = .playerManagement
        }
    }

    func selectControlLayout(_ layout: ControlLayout) {
        selectedControlLayout = layout
        UserDefaults.standard.set(layout.rawValue, forKey: "SnakeControlLayout")
    }

    func selectPlayer(_ player: String, skinsContext explicitSkinsContext: SkinsReturnContext? = nil) {
        let shouldReturnToStart = shouldReturnToStartAfterPlayerManagement
        let shouldReturnToVS = shouldReturnToVSAfterPlayerManagement
        let hadCurrentPlayer = !currentPlayerName.isEmpty

        currentPlayerName = player
        selectedSnakeSkin = ContentView.loadSnakeSkin(for: player)
        selectedPlayerForAction = nil
        playerToDelete = nil
        shouldReturnToStartAfterPlayerManagement = false
        shouldReturnToVSAfterPlayerManagement = false
        UserDefaults.standard.set(player, forKey: "CurrentSnakePlayer")

        if let explicitSkinsContext {
            skinsReturnContext = explicitSkinsContext
            screen = .skinsMenu
        } else if shouldReturnToVS {
            screen = .multiplayerVSMainMenu
        } else if shouldReturnToStart || hadCurrentPlayer {
            screen = .startMenu
        } else {
            screen = .playTypeSelection
        }
    }

    func playerSkinsReturnContext(shouldReturnToStart: Bool, shouldReturnToVS: Bool) -> SkinsReturnContext {
        if shouldReturnToVS {
            return .vsPlayerSelection
        }

        if shouldReturnToStart {
            return .playerSelection
        }

        if currentPlayerName.isEmpty {
            return .firstLaunchPlayerCreation
        }

        return .playerSelection
    }

    func addNewPlayer() {
        let trimmedName = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let finalName = String(trimmedName.prefix(10))
        let isFirstPlayer = players.isEmpty

        if !players.contains(finalName) {
            players.append(finalName)
            UserDefaults.standard.set(players, forKey: "SnakePlayers")
        }

        isNewPlayerNameFocused = false
        let returnContext: SkinsReturnContext
        if isFirstPlayer {
            returnContext = .firstLaunchPlayerCreation
        } else if shouldReturnToVSAfterPlayerManagement {
            returnContext = .newVSPlayerSelection
        } else {
            returnContext = .newPlayerSelection
        }
        selectPlayer(finalName, skinsContext: returnContext)
    }

    func saveSelectedSnakeSkin(_ skin: SnakeSkin) {
        guard !currentPlayerName.isEmpty else { return }
        UserDefaults.standard.set(skin.rawValue, forKey: ContentView.snakeSkinStorageKey(for: currentPlayerName))
    }

    func completeSkinsSelection() {
        switch skinsReturnContext {
        case .firstLaunchPlayerCreation, .newPlayerSelection, .newVSPlayerSelection:
            screen = .onboardingControl
        case .playerSelection:
            screen = .startMenu
        case .vsPlayerSelection:
            screen = .multiplayerVSMainMenu
        case .settings:
            screen = .settingsMenu
        case .vsSettings:
            shouldReturnToVSAfterSettings = true
            screen = .settingsMenu
        }
    }

    func completeOnboardingControlSelection() {
        selectControlLayout(selectedControlLayout)

        switch skinsReturnContext {
        case .firstLaunchPlayerCreation:
            screen = .playTypeSelection
        case .newPlayerSelection, .playerSelection:
            screen = .startMenu
        case .newVSPlayerSelection, .vsPlayerSelection:
            screen = .multiplayerVSMainMenu
        case .settings:
            screen = .settingsMenu
        case .vsSettings:
            shouldReturnToVSAfterSettings = true
            screen = .settingsMenu
        }
    }

    func pixelText(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .monospaced))
            .foregroundColor(Color.black.opacity(0.78))
    }
}


#Preview {
    ContentView()
}
