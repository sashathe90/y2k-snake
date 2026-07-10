//
//  SoundManager.swift
//  RetroSnake
//
//  Created by Sasha The on 05/05/2026.
//


import AudioToolbox
import AVFoundation
import Dispatch
import Foundation

final class SoundManager {
    static let shared = SoundManager()
    private let audioPerformanceTestMode = false

    private let wavPoolSizes = [
        "sfx_ui_click": 4,
        "sfx_eat_food": 4,
        "sfx_pill_pickup": 3,
        "sfx_super_food": 2,
        "sfx_scorpion_spawn": 2,
        "sfx_scorpion_good": 2,
        "sfx_lose_life": 2,
        "sfx_game_over": 2,
        "sfx_level_up": 2,
        "sfx_run_complete": 2,
        "sfx_boot": 2,
        "sfx_go": 2
    ]
    private let audioEngine = AVAudioEngine()
    private let sfxMixer = AVAudioMixerNode()
    private let sfxPlayerNodePoolSize = 8
    private var sfxVolume: Float = 1.0
    private let sfxVolumeMultipliers: [String: Float] = [
        "sfx_go": 0.5,
        "sfx_boot": 1.5,
        "sfx_ui_click": 0.5
    ]
    private var sfxBuffers: [String: AVAudioPCMBuffer] = [:]
    private var sfxPlayerNodes: [AVAudioPlayerNode] = []
    private var sfxPlayerNodeBusy: [Bool] = []
    private var sfxPlayerNodeGeneration: [Int] = []
    private var sfxNextPlayerNodeIndex = 0
    private let sfxPoolLock = NSLock()
    private var isAudioEngineReady = false
    private var systemSoundIDs: [String: SystemSoundID] = [:]
    private var wavPlayerPools: [String: [AVAudioPlayer]] = [:]
    private var menuMusicPlayer: AVAudioPlayer?
    private var lastBootPlaybackTime: Date?
    private var menuMusicRequestID = 0
    private let bootDuration: TimeInterval = 1.0
    private let menuMusicDelayAfterBoot: TimeInterval = 0.3
    
    private init() {
        configureAudioSession()
        prepareAudioEngineSFX()
        prepareSystemSounds()
        prepareWAVPlayers()
        prepareMenuMusic()
    }

    deinit {
        for soundID in systemSoundIDs.values {
            AudioServicesDisposeSystemSoundID(soundID)
        }
    }
    
    private func configureAudioSession() {
        refreshAudioSession()
    }

    private func refreshAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // Respect iPhone silent mode.
            try session.setCategory(.ambient, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to refresh audio session: \(error)")
        }
    }

    func refreshAudioSessionIfNeeded() {
        refreshAudioSession()
        startAudioEngineIfNeeded()
    }
    
    private var isSoundEnabled: Bool {
        UserDefaults.standard.object(forKey: "Y2KSnakeSoundEnabled") as? Bool ?? true
    }

    private func prepareAudioEngineSFX() {
        audioEngine.attach(sfxMixer)
        audioEngine.connect(sfxMixer, to: audioEngine.mainMixerNode, format: nil)
        sfxMixer.outputVolume = sfxVolume

        for _ in 0..<sfxPlayerNodePoolSize {
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: sfxMixer, format: nil)
            sfxPlayerNodes.append(playerNode)
            sfxPlayerNodeBusy.append(false)
            sfxPlayerNodeGeneration.append(0)
        }

        for soundName in wavPoolSizes.keys {
            guard let buffer = makeSFXBuffer(named: soundName) else { continue }
            sfxBuffers[soundName] = buffer
        }

        audioEngine.prepare()
        startAudioEngineIfNeeded()
        isAudioEngineReady = audioEngine.isRunning && !sfxBuffers.isEmpty && !sfxPlayerNodes.isEmpty
    }

    private func startAudioEngineIfNeeded() {
        guard !audioEngine.isRunning else { return }

        do {
            try audioEngine.start()
        } catch {
            isAudioEngineReady = false
            print("Failed to start AVAudioEngine: \(error)")
        }
    }

    private func makeSFXBuffer(named soundName: String) -> AVAudioPCMBuffer? {
        guard let url = wavURL(named: soundName) else {
            print("Missing WAV sound resource: \(soundName).wav")
            return nil
        }

        do {
            let file = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
            ) else {
                print("Failed to allocate SFX buffer for \(soundName)")
                return nil
            }

            try file.read(into: buffer)
            return buffer
        } catch {
            print("Failed to load SFX buffer \(soundName): \(error)")
            return nil
        }
    }

    private func prepareSystemSounds() {
        for soundName in wavPoolSizes.keys {
            guard let url = wavURL(named: soundName) else { continue }

            var soundID: SystemSoundID = 0
            let status = AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
            if status == kAudioServicesNoError {
                systemSoundIDs[soundName] = soundID
            } else {
                print("Failed to create SystemSoundID for \(soundName): \(status)")
            }
        }
    }

    private func prepareWAVPlayers() {
        for (soundName, poolSize) in wavPoolSizes {
            let players = (0..<poolSize).compactMap { _ -> AVAudioPlayer? in
                guard let player = makeWAVPlayer(named: soundName) else { return nil }
                player.prepareToPlay()
                return player
            }

            if !players.isEmpty {
                wavPlayerPools[soundName] = players
            }
        }
    }

    private func wavURL(named soundName: String) -> URL? {
        Bundle.main.url(
            forResource: soundName,
            withExtension: "wav",
            subdirectory: "Audio/SFX"
        ) ?? Bundle.main.url(forResource: soundName, withExtension: "wav")
    }

    private func musicURL(named musicName: String) -> URL? {
        Bundle.main.url(
            forResource: musicName,
            withExtension: "wav",
            subdirectory: "Audio/Music"
        ) ?? Bundle.main.url(forResource: musicName, withExtension: "wav")
    }

    private func makeWAVPlayer(named soundName: String) -> AVAudioPlayer? {
        let url = wavURL(named: soundName)
        guard let url else {
            print("Missing WAV sound resource: \(soundName).wav")
            return nil
        }

        do {
            return try AVAudioPlayer(contentsOf: url)
        } catch {
            print("Failed to load WAV sound \(soundName): \(error)")
            return nil
        }
    }

    private func volumeMultiplier(for soundName: String) -> Float {
        sfxVolumeMultipliers[soundName] ?? 1.0
    }

    private func prepareMenuMusic() {
        guard let url = musicURL(named: "music_main_menu") else {
            print("Missing menu music resource: music_main_menu.wav")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            menuMusicPlayer = player
        } catch {
            print("Failed to load menu music: \(error)")
        }
    }

    func playMenuMusic() {
        guard !audioPerformanceTestMode else { return }
        guard isSoundEnabled else {
            stopMenuMusic()
            return
        }
        guard let menuMusicPlayer else { return }
        guard !menuMusicPlayer.isPlaying else { return }

        if let lastBootPlaybackTime {
            let delay = bootDuration + menuMusicDelayAfterBoot - Date().timeIntervalSince(lastBootPlaybackTime)
            if delay > 0 {
                menuMusicRequestID += 1
                let requestID = menuMusicRequestID
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    guard self.menuMusicRequestID == requestID else { return }
                    self.playMenuMusic()
                }
                return
            }
        }

        menuMusicPlayer.currentTime = 0
        menuMusicPlayer.play()
    }

    func stopMenuMusic() {
        menuMusicRequestID += 1
        guard let menuMusicPlayer else { return }
        if menuMusicPlayer.isPlaying {
            menuMusicPlayer.stop()
        }
        menuMusicPlayer.currentTime = 0
    }

    func pauseAllAudioForAppLifecycle() {
        stopMenuMusic()
        sfxPoolLock.lock()
        for index in sfxPlayerNodeBusy.indices {
            sfxPlayerNodeGeneration[index] += 1
            sfxPlayerNodeBusy[index] = false
        }
        sfxPoolLock.unlock()

        for playerNode in sfxPlayerNodes {
            if playerNode.isPlaying {
                playerNode.stop()
            }
        }
    }

    func resumeAudioForAppLifecycle() {
        guard isSoundEnabled else {
            stopMenuMusic()
            return
        }

        startAudioEngineIfNeeded()
        playMenuMusic()
    }

    @discardableResult
    private func playEngineSFX(_ soundName: String) -> Bool {
        guard isSoundEnabled else { return false }
        guard isAudioEngineReady, audioEngine.isRunning else { return false }
        guard let buffer = sfxBuffers[soundName] else { return false }
        guard let playerIndex = reserveSFXPlayerNode() else { return false }

        let playerNode = sfxPlayerNodes[playerIndex]
        if playerNode.isPlaying {
            playerNode.stop()
        }

        sfxMixer.outputVolume = sfxVolume
        playerNode.volume = volumeMultiplier(for: soundName)
        let generation = sfxPlayerNodeGeneration[playerIndex]
        playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
            self?.releaseSFXPlayerNode(at: playerIndex, generation: generation)
        }
        playerNode.play()
        return true
    }

    private func reserveSFXPlayerNode() -> Int? {
        sfxPoolLock.lock()
        defer { sfxPoolLock.unlock() }

        guard !sfxPlayerNodes.isEmpty else { return nil }

        let playerIndex = sfxPlayerNodeBusy.firstIndex(of: false) ?? sfxNextPlayerNodeIndex
        sfxPlayerNodeBusy[playerIndex] = true
        sfxPlayerNodeGeneration[playerIndex] += 1
        sfxNextPlayerNodeIndex = (playerIndex + 1) % sfxPlayerNodes.count
        return playerIndex
    }

    private func releaseSFXPlayerNode(at index: Int, generation: Int) {
        sfxPoolLock.lock()
        defer { sfxPoolLock.unlock() }

        guard sfxPlayerNodeGeneration.indices.contains(index) else { return }
        guard sfxPlayerNodeGeneration[index] == generation else { return }
        sfxPlayerNodeBusy[index] = false
    }

    @discardableResult
    private func playSystemSFX(_ soundName: String) -> Bool {
        guard isSoundEnabled else { return false }
        guard AVAudioSession.sharedInstance().outputVolume > 0.01 else { return false }
        guard let soundID = systemSoundIDs[soundName] else { return false }

        AudioServicesPlaySystemSound(soundID)
        return true
    }

    @discardableResult
    private func playWAV(_ soundName: String) -> Bool {
        guard isSoundEnabled else { return false }
        guard let pool = wavPlayerPools[soundName], !pool.isEmpty else { return false }

        let player = pool.first(where: { !$0.isPlaying }) ?? pool[0]
        player.currentTime = 0
        player.volume = min(sfxVolume * volumeMultiplier(for: soundName), 1.0)
        return player.play()
    }

    @discardableResult
    private func playProductionSFX(_ soundName: String) -> Bool {
        playEngineSFX(soundName) || playSystemSFX(soundName) || playWAV(soundName)
    }
    
    // LEGACY SYSTEM SOUND
    // Preserved for comparison and rollback.
    private func playSystemSoundLegacy(_ soundID: SystemSoundID) {
        guard isSoundEnabled else { return }
        refreshAudioSession()
        guard AVAudioSession.sharedInstance().outputVolume > 0.01 else { return }
        AudioServicesPlaySystemSound(soundID)
    }
    
    func playFood() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_eat_food") {
            playFoodLegacy()
        }
    }
    
    func playSuperFood() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_super_food") {
            playSuperFoodLegacy()
        }
    }

    func playPillPickup() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_pill_pickup") {
            playMenuClickLegacy()
        }
    }

    func playScorpionSpawn() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_scorpion_spawn") {
            playSuperFoodLegacy()
        }
    }

    func playScorpionGood() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_scorpion_good") {
            playExtraLifeLegacy()
        }
    }

    func playLoseLife() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_lose_life") {
            playHitLegacy()
        }
    }

    func playGameOver() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_game_over") {
            playGameOverLegacy()
        }
    }

    func playWin() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_run_complete") {
            playWinLegacy()
        }
    }

    func playLevelUp() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_level_up") {
            playLevelUpLegacy()
        }
    }

    func playRetroBoot() {
        guard !audioPerformanceTestMode else { return }
        lastBootPlaybackTime = Date()
        if !playProductionSFX("sfx_boot") {
            playRetroBootLegacy()
        }
    }

    // MARK: - Legacy system sounds

    func playFoodLegacy() {
        playSystemSoundLegacy(1104)
    }

    func playSuperFoodLegacy() {
        playSystemSoundLegacy(1105)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playSystemSoundLegacy(1105)
        }
    }

    func playExtraLifeLegacy() {
        playSystemSoundLegacy(1110)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            self.playSystemSoundLegacy(1113)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            self.playSystemSoundLegacy(1114)
        }
    }

    func playExtraLife() {
        playExtraLifeLegacy()
    }
    
    func playHitLegacy() {
        playSystemSoundLegacy(1053)
    }

    func playHit() {
        playHitLegacy()
    }
    
    func playGameOverLegacy() {
        playSystemSoundLegacy(1053)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            self.playSystemSoundLegacy(1053)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            self.playSystemSoundLegacy(1053)
        }
    }
    
    func playWinLegacy() {
        playSystemSoundLegacy(1104)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            self.playSystemSoundLegacy(1105)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            self.playSystemSoundLegacy(1106)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            self.playSystemSoundLegacy(1105)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            self.playSystemSoundLegacy(1106)
        }
    }
    
    func playLevelUpLegacy() {
        playSystemSoundLegacy(1104)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playSystemSoundLegacy(1105)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            self.playSystemSoundLegacy(1106)
        }
    }
    
    func playSpeedBoost() {
        playSystemSoundLegacy(1113)
    }
    
    func playSlowEffect() {
        playSystemSoundLegacy(1112)
    }
    
    func playInvertEffect() {
        playSystemSoundLegacy(1109)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.playSystemSoundLegacy(1108)
        }
    }
    
    func playRainbowEffect() {
        playSystemSoundLegacy(1104)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.playSystemSoundLegacy(1105)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.playSystemSoundLegacy(1106)
        }
    }
    
    func playFlickerEffect() {
        playSystemSoundLegacy(1157)
    }
    
    func playFinalCountdownTick() {
        playSystemSoundLegacy(1103)
    }
    
    func playStartCountdownTick() {
        playSystemSoundLegacy(1103)
    }
    
    func playStartGo() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_go") {
            playStartGoLegacy()
        }
    }

    func playStartGoLegacy() {
        playSystemSoundLegacy(1113)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playSystemSoundLegacy(1106)
        }
    }
    
    func playMenuClick() {
        guard !audioPerformanceTestMode else { return }
        if !playProductionSFX("sfx_ui_click") {
            playMenuClickLegacy()
        }
    }

    func playMenuClickLegacy() {
        playSystemSoundLegacy(1104)
    }

    func playRetroBootLegacy() {
        playSystemSoundLegacy(1104)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.playSystemSoundLegacy(1106)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            self.playSystemSoundLegacy(1113)
        }
    }
}
