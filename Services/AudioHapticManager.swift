import SwiftUI
import AVFoundation
import CoreHaptics
import AudioToolbox

class AudioHapticManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioHapticManager()
    private var engine: CHHapticEngine?
    
    // Audio Players
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    
    private override init() {
        super.init()
        prepareHaptics()
        configureAudioSession()
    }
    
    // MARK: - Settings Persistence
    var isMusicEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isMusicEnabled") }
    }
    
    var isSFXEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isSFXEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isSFXEnabled") }
    }
    
    var isHapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isHapticsEnabled") }
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true // Prevent BGM from interfering with the haptics engine
            try engine?.start()
        } catch {
            print("Failed to start haptics engine: \(error.localizedDescription)")
            engine = nil
        }
    }
    
    // Haptic Generators Cache
    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    
    // MARK: - UI Haptics (Standard Apple Feel)
    
    func playUITap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isHapticsEnabled else { return }
        
        let generator: UIImpactFeedbackGenerator
        if let cached = impactGenerators[style] {
            generator = cached
        } else {
            generator = UIImpactFeedbackGenerator(style: style)
            impactGenerators[style] = generator
        }
        
        generator.prepare()
        generator.impactOccurred()
    }
    
    func playSuccessHaptic() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    func playFailureHaptic() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    func playWarningHaptic() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    // MARK: - Gameplay Haptics (CoreHaptics for texture)
    
    func playDashHaptic() {
        guard isHapticsEnabled else { return }
        playUITap(style: .rigid)
    }
    
    func playNearMissHaptic() {
        guard isHapticsEnabled else { return }
        playUITap(style: .rigid)
    }
    
    func playShardHaptic() {
        guard isHapticsEnabled else { return }
        playSuccessHaptic()
    }
    
    func playHeartbeatThump() {
        guard isHapticsEnabled else { return }
        playUITap(style: .heavy)
    }
    
    func playEnhancedCollision() {
        guard isHapticsEnabled, CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            playFailureHaptic() // Fallback
            return
        }
        
        do {
            try engine?.start()
            
            // 1. Initial Sharp Impact (The Hit)
            let impactIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let impactSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            let impactEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [impactIntensity, impactSharpness], relativeTime: 0)
            
            // 2. Secondary Rumble (The Aftermath / Explosion)
            let rumbleIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let rumbleSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            let rumbleEvent = CHHapticEvent(eventType: .hapticContinuous, parameters: [rumbleIntensity, rumbleSharpness], relativeTime: 0.05, duration: 0.25)
            
            // 3. Optional Fade out curve
            let decayCurve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.05, value: 1.0),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.3, value: 0.0)
                ],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(events: [impactEvent, rumbleEvent], parameterCurves: [decayCurve])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play enhanced collision haptic: \(error)")
            playFailureHaptic()
        }
    }
    
    func playEnhancedPowerUp() {
        guard isHapticsEnabled, CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            playSuccessHaptic() // Fallback
            return
        }
        
        do {
            try engine?.start()
            
            // A rising, pleasant "zip" feeling
            var events = [CHHapticEvent]()
            
            for i in 0..<5 {
                let intensity = Float(i) * 0.2 + 0.2 // Rises from 0.2 to 1.0
                let sharpness = Float(i) * 0.2 + 0.2 // Rises from 0.2 to 1.0
                let time = TimeInterval(i) * 0.04    // Quick succession
                
                let p1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
                let p2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                let event = CHHapticEvent(eventType: .hapticTransient, parameters: [p1, p2], relativeTime: time)
                events.append(event)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play enhanced powerup haptic: \(error)")
            playSuccessHaptic()
        }
    }
    
    // Legacy fallback (to not break compilation right away, but we will replace usages)
    func playHaptic(intensity: Float) {
        if intensity > 0.7 {
            playUITap(style: .heavy)
        } else if intensity > 0.4 {
            playUITap(style: .medium)
        } else {
            playUITap(style: .light)
        }
    }
    
    // MARK: - Music
    
    func playBackgroundMusic(named filename: String, withExtension ext: String = "m4a") {
        guard isMusicEnabled else { return }
        
        let bundle = Bundle.main
        var url: URL?
        
        let extensions = [ext, "mp3", "wav", "ogg"]
        for extensionName in extensions {
            if let foundUrl = bundle.url(forResource: filename, withExtension: extensionName) {
                url = foundUrl
                break
            }
            if let foundUrl = bundle.url(forResource: filename, withExtension: extensionName, subdirectory: "Resources") {
                url = foundUrl
                break
            }
            // Fallback: check manual "Resources/" prefix
            if let foundUrl = bundle.url(forResource: "Resources/\(filename)", withExtension: extensionName) {
                url = foundUrl
                break
            }
        }
        
        guard let finalUrl = url else {
            print("Could not find music file: \(filename) with extensions \(extensions)")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: finalUrl)
            backgroundMusicPlayer?.numberOfLoops = -1 // Infinite loop
            backgroundMusicPlayer?.volume = 0.4 // Increased volume so it is audible
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
        } catch {
            print("Could not create audio player: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func resumeBackgroundMusic() {
        backgroundMusicPlayer?.play()
    }
    
    // MARK: - Sound Effects
    
    // Cache for high-frequency sounds
    private var cachedPlayers: [String: AVAudioPlayer] = [:]

    func playSound(named soundName: String) {
        guard isSFXEnabled else { return }
        
        // Fast path for rapid sounds to prevent audio engine drops
        if soundName == "dragon-studio-keyboard-typing-sound-effect-335503", let cached = cachedPlayers[soundName] {
            cached.play()
            return
        }
        
        // Try multiple bundle locations and extensions
        let bundle = Bundle.main
        var url: URL?
        
        let extensions = ["m4a", "mp3", "wav", "ogg"]
        for extensionName in extensions {
            if let foundUrl = bundle.url(forResource: soundName, withExtension: extensionName) {
                url = foundUrl
                break
            }
            if let foundUrl = bundle.url(forResource: "Resources/\(soundName)", withExtension: extensionName) {
                url = foundUrl
                break
            }
        }
        
        // Try to play custom sound file first
        if let finalUrl = url {
            do {
                let player = try AVAudioPlayer(contentsOf: finalUrl)
                player.volume = 0.5 // Lower volume for typing/FX
                player.delegate = self
                
                if soundName == "dragon-studio-keyboard-typing-sound-effect-335503" {
                    player.numberOfLoops = -1 // Loop the continuous typing track
                }
                
                player.prepareToPlay() 
                player.play()
                
                if soundName == "dragon-studio-keyboard-typing-sound-effect-335503" {
                    // Cache it for next rapid call
                    cachedPlayers[soundName] = player
                } else {
                    let id = UUID().uuidString
                    soundEffectPlayers[id] = player
                }
            } catch {
                print("Failed to play custom sound: \(error)")
                playSystemSoundFallback(named: soundName)
            }
        } else {
            playSystemSoundFallback(named: soundName)
        }
    }
    
    func stopSound(named soundName: String) {
        if let cached = cachedPlayers[soundName] {
            cached.stop()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Cleanup finished players
        for (id, p) in soundEffectPlayers {
            if p == player {
                soundEffectPlayers.removeValue(forKey: id)
                break
            }
        }
    }
    
    private func playSystemSoundFallback(named soundName: String) {
        guard isSFXEnabled else { return }
        
        switch soundName {
        case "PowerUp":
            AudioServicesPlaySystemSound(1113)
        case "GameOver":
            AudioServicesPlaySystemSound(1110)
        case "ScoreMultiplier":
            AudioServicesPlaySystemSound(1157)
        default:
            // Generic beep for others
            AudioServicesPlaySystemSound(1057)
        }
    }
}
