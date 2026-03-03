import SwiftUI
import Combine

public class GameViewModel: ObservableObject {
    @Published var playerX: CGFloat = 0
    @Published var obstacleRows: [ObstacleRow] = []
    @Published var score: Int = 0
    
    // Restoration of deleted properties
    @Published var alive: Bool = true
    @Published var showHighScoreBadge = false
    @Published var shieldActive = false
    @Published var powerUp: Obstacle? = nil
    @Published var restartAvailable = false
    @Published var gameWon = false 
    
    // Debug Mode (Disabled for Production)
    @Published var debugMode = false
    @Published var showRevivePopup = false

    // New states for score multiplier power-up
    @Published var multiplierActive = false
    @Published var multiplierTimer = 0
    
    // Collision animation effect
    @Published var showCollisionEffect = false
    @Published var collisionPosition: CGPoint = .zero
    
    // Revive Invincibility Reference
    @Published var isInvincible = false
    
    @Published var selectedLevel = 1
    @Published var levelComplete = false
    
    // Pause State
    @Published var isPaused = false
    
    var unlockedLevels: Int {
        get { UserDefaults.standard.integer(forKey: "unlockedLevels") == 0 ? 1 : UserDefaults.standard.integer(forKey: "unlockedLevels") }
        set { UserDefaults.standard.set(newValue, forKey: "unlockedLevels") }
    }

    @Published var gameMode: GameMode = .endless

    // Constants - Physics & Gameplay
    let playerRadius: CGFloat = 28
    let gameHeight: CGFloat = 560
    let gameWidth: CGFloat = 350
    
    // Improved Physics Constants
    // Apple-quality feel: Snappy but smooth
    // No "drag" or "friction" on x-axis for immediate responsiveness
    
    var rowSpacing: CGFloat {
        // Dynamic spacing based on speed to ensure playability
        // 120 base + speed buffer to prevent unavoidable walls
        120 + currentSpeed() * 25
    }
    
    private var spawnToggle = false
    internal var timer: Timer? = nil
    private var lastRowY: CGFloat = -1000
    private var gameSize: CGSize = UIScreen.main.bounds.size // Default, updated by startGame for accuracy
    
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "highScore") }
        set { UserDefaults.standard.set(newValue, forKey: "highScore") }
    }

    func startGame(level: Int = 1, size: CGSize, newGame: Bool = true) {
        if newGame {
            selectedLevel = level
            obstacleRows = []
            score = 0
            playerX = 0
            alive = true
            gameWon = false
            levelComplete = false
            shieldActive = false
            isInvincible = false
            powerUp = nil
            showHighScoreBadge = false
            restartAvailable = false
            lastRowY = -1000
            isPaused = false
            
            multiplierActive = false
            multiplierTimer = 0
            
            showCollisionEffect = false
            collisionPosition = .zero
            showRevivePopup = false
            
            timer?.invalidate()
            
            spawnToggle = false
            
            let firstBaseY: CGFloat = 250
            let verticalOffset = rowSpacing * 0.18
            let firstY = firstBaseY - verticalOffset
            
            spawnRow(at: firstY)
            lastRowY = firstY
        }
        
        self.gameSize = size // Update active game size
        
        // Single Authoritative Game Loop
        startTimer()
    }
    
    func updateGameSize(size: CGSize) {
        if size.width > 50 && size.height > 50 {
            self.gameSize = size
        }
    }
    
    private func startTimer() {
        timer?.invalidate() // Ensure no duplicate timers

        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.gameLoop()
        }
    }
    
    // Central Game Loop
    func gameLoop() {
        // 1. Check Pause State
        if isPaused { return }
        
        // 1.5 Check Revive Popup State (Freeze Game)
        if showRevivePopup { return }
        
        // 2. Check Game End States
        if !alive || gameWon || levelComplete {
            // Do NOT invalidate timer here if we are just waiting for revive input
            // But effectively stop updates
            
            timer?.invalidate()
            return
        }
        
        // 3. Update Physics & Game State
        updateRows(size: gameSize)
        updatePowerUp(size: gameSize)
        checkCollisions(size: gameSize) // Uses Extension

        // 4. Spawning Logic
        // Spawn a new row if the last row has moved down far enough
        if let lastRow = obstacleRows.last {
            if lastRow.y > lastRowY + rowSpacing {
                spawnToggle.toggle()
                
                let verticalOffset = rowSpacing * 0.18
                let yBase = lastRow.y - rowSpacing
                let yAdjusted = spawnToggle ? yBase - verticalOffset : yBase + verticalOffset
                
                // Ensure rows never get too close
                let minGap = rowSpacing * 0.6
                let finalY = min(yAdjusted, lastRow.y - minGap)
                
                spawnRow(at: finalY)
                lastRowY = finalY
            }
        }

        // 5. Power-Up Spawning logic
        // Spawn power-up every ~200 ticks only in Easy and Medium phases
        if score > 0 && score % 200 == 0 && powerUp == nil && score <= 300 {
            // 20% chance to spawn scoreMultiplier power-up, else shield
            let spawnMultiplier = Bool.random() && Bool.random()
            if spawnMultiplier {
                spawnScoreMultiplierPowerUp(size: gameSize)
            } else {
                spawnPowerUp(size: gameSize)
            }
        }
        
        // Spawn revive power-up (Endless only, Rare)
        if gameMode == .endless && score > 0 && score % 2500 == 0 && powerUp == nil {
            spawnRevivePowerUp(size: gameSize)
        }

        // 6. Score & Progression
        if multiplierActive {
            score += 2
            multiplierTimer -= 1
            if multiplierTimer <= 0 {
                multiplierActive = false
            }
        } else {
            score += 1
        }
        
        // Check Level Progression (Story Mode Only)
        if gameMode == .story {
            let target = selectedLevel * 1000
            
            if score >= target {
                if selectedLevel < 30 {
                    // Level Complete (Unlock next)
                    levelComplete = true
                    AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
                    AudioHapticManager.shared.playSuccessHaptic()
                    
                    // Unlock next level if not already unlocked
                    if unlockedLevels < selectedLevel + 1 {
                        unlockedLevels = selectedLevel + 1
                    }
                } else {
                    // Final Level (Level 30) -> Game Won (Wake Up)
                    gameWon = true
                    AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
                    AudioHapticManager.shared.playSuccessHaptic()
                }
            }
        }
    }
    
    func startNextLevel(size: CGSize) {
        if selectedLevel < 30 {
            startGame(level: selectedLevel + 1, size: size, newGame: true)
        }
    }

    func restartGame(size: CGSize) {
        withAnimation {
            startGame(level: selectedLevel, size: size)
        }
    }
    
    func stopGame() {
        timer?.invalidate()
    }
    
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            AudioHapticManager.shared.pauseBackgroundMusic()
        } else {
            AudioHapticManager.shared.resumeBackgroundMusic()
        }
        AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
        AudioHapticManager.shared.playUITap(style: .medium)
    }

    func currentSpeed() -> CGFloat {
        // CONTINUOUS SCALING for endless mode (no cap at 3000)
        // Uses diminishing returns curve for smooth difficulty progression
        let minSpeed: CGFloat = 1.2
        let maxSpeed: CGFloat = 3.7
        let targetScore: CGFloat = 5000 // Reach max speed at 5000, then maintain
        
        // Logarithmic scaling with diminishing returns
        let progress = min(CGFloat(score) / targetScore, 1.0)
        let easedProgress = sqrt(progress) // Square root for smooth curve
        
        // Level-based base speed increase
        let levelMultiplier = CGFloat(selectedLevel - 1) * 0.05 // Mild increase per level
        
        return minSpeed + (maxSpeed - minSpeed) * easedProgress + levelMultiplier
    }
    
    // Heart Rate Logic
    var heartRate: Int {
        // Base 60, increases with speed/intensity
        let base = 60
        let intensity = Int(currentSpeed() * 20)
        return base + intensity
    }
    
    // Revive System - Consolidated to use StoreManager
    // We remove the local 'defibrillators' and use StoreManager.shared.reviveCount
    
    func checkReviveAvailability() {
        // Allow Revive in both Endless and Story modes
        if StoreManager.shared.reviveCount > 0 {
            showRevivePopup = true // Use the popup style
            // isPaused = true // Don't pause whole game loop logic per se, just stop updates
        } else {
            // No revive available
            alive = false
            triggerGameOverSequence()
        }
    }
    
    // Classic Revive (Story Mode / Old Style) - if needed
    // Keeping for compatibility but directing to generic revive flow
    func revive() {
        useRevive()
    }
    
    // Unified Revive System
    func useRevive() {
        if StoreManager.shared.useRevive() {
            // CRITICAL: Set these BEFORE restarting timer
            alive = true
            showRevivePopup = false
            
            // Gameplay Gameplay benefits
            shieldActive = true // Give shield on revive for protection
            isInvincible = true // Enable invincibility
            
            AudioHapticManager.shared.playSound(named: "PowerUp")
            AudioHapticManager.shared.playEnhancedPowerUp()
            
            // Restart the game timer logic
             startTimer()
            
            // Remove shield and invincibility after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.shieldActive = false
                self?.isInvincible = false
            }
        } else {
            // Failed to use revive (count 0?), end game
            skipRevive()
        }
    }
    
    func skipRevive() {
        showRevivePopup = false
        alive = false // Ensure dead state
        
        triggerGameOverSequence()
    }
    
    private func triggerGameOverSequence() {
        // Standard death flow
        // Only add score if it hasn't been added yet (prevent double counting)
        // Actually, we don't add score to balance here in previous code?
        // Ah, it was: StoreManager.shared.balance += score
        
        StoreManager.shared.balance += score
        
        if score > highScore {
            highScore = score
            showHighScoreBadge = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.restartAvailable = true
        }
    }
    
    func updateRows(size: CGSize) {
        let actualSpeed = currentSpeed()

        for rowIndex in obstacleRows.indices {
            obstacleRows[rowIndex].y += actualSpeed

            for obsIndex in obstacleRows[rowIndex].obstacles.indices {
                var obs = obstacleRows[rowIndex].obstacles[obsIndex]
                obs.y = obstacleRows[rowIndex].y

                if obs.type == .moving {
                    obs.x += obs.dx

                    let gapRange = obstacleRows[rowIndex].gapRange
                    let halfWidth = obs.width / 2

                    let leftBound: CGFloat
                    let rightBound: CGFloat

                    if obs.x + halfWidth <= gapRange.lowerBound {
                        leftBound = -gameWidth/2 + halfWidth
                        rightBound = gapRange.lowerBound - halfWidth
                    } else if obs.x - halfWidth >= gapRange.upperBound {
                        leftBound = gapRange.upperBound + halfWidth
                        rightBound = gameWidth/2 - halfWidth
                    } else {
                        let distToLeft = abs(obs.x - gapRange.lowerBound)
                        let distToRight = abs(obs.x - gapRange.upperBound)
                        if distToLeft < distToRight {
                            obs.x = gapRange.lowerBound - halfWidth
                            leftBound = -gameWidth/2 + halfWidth
                            rightBound = gapRange.lowerBound - halfWidth
                        } else {
                            obs.x = gapRange.upperBound + halfWidth
                            leftBound = gapRange.upperBound + halfWidth
                            rightBound = gameWidth/2 - halfWidth
                        }
                    }

                    if obs.x < leftBound {
                        obs.x = leftBound
                        obs.dx = -obs.dx
                    } else if obs.x > rightBound {
                        obs.x = rightBound
                        obs.dx = -obs.dx
                    }
                }

                obstacleRows[rowIndex].obstacles[obsIndex] = obs
            }
        }

        obstacleRows.removeAll { $0.y > size.height + 40 }
    }

    func updatePowerUp(size: CGSize) {
        guard var pu = powerUp else { return }
        let speed = currentSpeed()
        pu.y += speed
        if pu.y > size.height + 40 {
            powerUp = nil
            return
        }
        powerUp = pu
    }

    func prepareHaptics() {
        AudioHapticManager.shared.prepareHaptics()
    }
}
