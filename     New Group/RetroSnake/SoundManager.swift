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

    private let wavPoolSizes = [
        "sfx_ui_click": 4,
        "sfx_eat_food": 4,
        "sfx_pill_pickup": 3,
        "sfx_super_food": 2,
        "sfx_scorpion_spawn": 2,
        "sfx_scorpion_good": 2,
        "sfx_lose_life": 2
    ]
    private var wavPlayerPools: [String: [AVAudioPlayer]] = [:]
    
    private init() {
        configureAudioSession()
        prepareWAVPlayers()
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
    }
    
    private var isSoundEnabled: Bool {
        UserDefaults.standard.object(forKey: "Y2KSnakeSoundEnabled") as? Bool ?? true
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

    private func makeWAVPlayer(named soundName: String) -> AVAudioPlayer? {
        let url = Bundle.main.url(
            forResource: soundName,
            withExtension: "wav",
            subdirectory: "Audio/SFX"
        ) ?? Bundle.main.url(forResource: soundName, withExtension: "wav")

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

    @discardableResult
    private func playWAV(_ soundName: String) -> Bool {
        guard isSoundEnabled else { return false }
        guard let pool = wavPlayerPools[soundName], !pool.isEmpty else { return false }

        let player = pool.first(where: { !$0.isPlaying }) ?? pool[0]
        player.currentTime = 0
        return player.play()
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
        if !playWAV("sfx_eat_food") {
            playFoodLegacy()
        }
    }
    
    func playSuperFood() {
        if !playWAV("sfx_super_food") {
            playSuperFoodLegacy()
        }
    }

    func playPillPickup() {
        if !playWAV("sfx_pill_pickup") {
            playMenuClickLegacy()
        }
    }

    func playScorpionSpawn() {
        if !playWAV("sfx_scorpion_spawn") {
            playSuperFoodLegacy()
        }
    }

    func playScorpionGood() {
        if !playWAV("sfx_scorpion_good") {
            playExtraLifeLegacy()
        }
    }

    func playLoseLife() {
        if !playWAV("sfx_lose_life") {
            playHitLegacy()
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
    
    func playGameOver() {
        playSystemSoundLegacy(1053)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            self.playSystemSoundLegacy(1053)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            self.playSystemSoundLegacy(1053)
        }
    }
    
    func playWin() {
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
    
    func playLevelUp() {
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
        playSystemSoundLegacy(1113)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playSystemSoundLegacy(1106)
        }
    }
    
    func playMenuClick() {
        if !playWAV("sfx_ui_click") {
            playMenuClickLegacy()
        }
    }

    func playMenuClickLegacy() {
        playSystemSoundLegacy(1104)
    }

    func playRetroBoot() {
        playSystemSoundLegacy(1104)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.playSystemSoundLegacy(1106)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            self.playSystemSoundLegacy(1113)
        }
    }
}
