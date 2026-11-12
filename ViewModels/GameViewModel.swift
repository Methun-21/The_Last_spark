import SwiftUI
import Combine

public class GameViewModel: ObservableObject {
    @Published var playerX: CGFloat = 0
    @Published var obstacleRows: [ObstacleRow] = []
    @Published var score: Int = 0
    
    // Player and game state
    @Published var alive: Bool = true
    @Published var showHighScoreBadge = false
    @Published var shieldActive = false
    @Published var powerUp: Obstacle? = nil
    @Published var restartAvailable = false
    @Published var gameWon = false 
    
    // Debug & Revive
    @Published var debugMode = false
    @Published var showRevivePopup = false

    // Multiplier state
    @Published var multiplierActive = false
    @Published var multiplierTimer = 0
    
    // Visual FX & Hit Feedback
    @Published var showCollisionEffect = false
    @Published var collisionPosition: CGPoint = .zero
    @Published var screenShakeOffset: CGFloat = 0
    @Published var isInvincible = false
    
    // Synaptic Dash — no longer uses dashEnergy, now purely count-based
    @Published var dashEnergy: Double = 1.0 // kept for future visual effects only
    @Published var isDashing = false
    private var dashTimer: CGFloat = 0
    
    // TOUGHNESS: Near-Miss / Grazing Mechanics
    @Published var nearMissStreak: Int = 0
    @Published var showNearMissToast: Bool = false
    @Published var nearMissText: String = ""
    @Published var nearMissPosition: CGPoint = .zero
    
    // MEANING: Story Chapters & Memory Shards
    @Published var selectedLevel = 1
    @Published var levelComplete = false
    @Published var levelShardsCollected = 0
    
    // LEVEL COMPLETION: Synaptic Gateway Finish Sequence
    @Published var isApproachingGate = false
    @Published var isPassingGate = false
    @Published var gateY: CGFloat = -300
    @Published var victoryFlashOpacity: Double = 0.0
    @Published var splitObstaclesOffset: CGFloat = 0.0
    
    // Pause State
    @Published var isPaused = false
    
    var unlockedLevels: Int {
        get { UserDefaults.standard.integer(forKey: "unlockedLevels") == 0 ? 1 : UserDefaults.standard.integer(forKey: "unlockedLevels") }
        set { UserDefaults.standard.set(newValue, forKey: "unlockedLevels") }
    }

    @Published var gameMode: GameMode = .endless

    // Constants - Physics & Gameplay
    let playerRadius: CGFloat = 26
    let gameHeight: CGFloat = 560
    
    // Dynamic playable corridor (Responsive on iPhone and iPad)
    var gameWidth: CGFloat {
        let width = gameSize.width
        if width > 0 {
            return min(max(width * 0.88, 330), 460)
        }
        return 360
    }
    
    var rowSpacing: CGFloat {
        // Dynamic spacing based on speed to ensure playability
        130 + currentSpeed() * 24
    }
    
    private var spawnToggle = false
    internal var timer: Timer? = nil
    private var lastRowY: CGFloat = -1000
    private var gameSize: CGSize = UIScreen.main.bounds.size
    private var lastFrameTime: TimeInterval = 0
    
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
            
            // Reset Dash & Grazing
            dashEnergy = 1.0
            isDashing = false
            dashTimer = 0
            nearMissStreak = 0
            showNearMissToast = false
            levelShardsCollected = 0
            
            // Reset Gateway Finish State
            isApproachingGate = false
            isPassingGate = false
            gateY = -300
            victoryFlashOpacity = 0.0
            splitObstaclesOffset = 0.0
            
            multiplierActive = false
            multiplierTimer = 0
            
            showCollisionEffect = false
            collisionPosition = .zero
            showRevivePopup = false
            screenShakeOffset = 0
            
            timer?.invalidate()
            spawnToggle = false
            lastFrameTime = 0
            
            let firstBaseY: CGFloat = 240
            let verticalOffset = rowSpacing * 0.18
            let firstY = firstBaseY - verticalOffset
            
            spawnRow(at: firstY)
            lastRowY = firstY
        }
        
        self.gameSize = size
        startTimer()
    }
    
    func updateGameSize(size: CGSize) {
        if size.width > 50 && size.height > 50 {
            self.gameSize = size
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        lastFrameTime = CACurrentMediaTime()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.gameLoop()
        }
    }
    
    // Central Game Loop with Delta Time
    func gameLoop() {
        if isPaused || showRevivePopup { return }
        
        if !alive || gameWon || levelComplete {
            timer?.invalidate()
            return
        }
        
        // Calculate Delta Time (Vsync / DisplayLink scale)
        let now = CACurrentMediaTime()
        let dt: CGFloat
        if lastFrameTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = CGFloat(min(now - lastFrameTime, 0.05)) // Clamped to prevent huge jumps
        }
        lastFrameTime = now
        
        // 1. Dash Timer (no auto-recharge — dash is now a purchasable consumable)
        if isDashing {
            dashTimer -= dt
            if dashTimer <= 0 {
                isDashing = false
                // Brief grace period so spark never dies clipping out of a barrier
                isInvincible = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
                    self?.isInvincible = false
                }
            }
        }
        
        // 2. Update Physics & Game State
        updateRows(size: gameSize, dt: dt)
        updatePowerUp(size: gameSize, dt: dt)
        updateGate(size: gameSize, dt: dt)
        checkCollisions(size: gameSize)

        // 3. Spawning Logic (Stop spawning rows when finish gateway approaches!)
        if !isApproachingGate, let lastRow = obstacleRows.last {
            if lastRow.y > lastRowY + rowSpacing {
                spawnToggle.toggle()
                
                let verticalOffset = rowSpacing * 0.18
                let yBase = lastRow.y - rowSpacing
                let yAdjusted = spawnToggle ? yBase - verticalOffset : yBase + verticalOffset
                
                let minGap = rowSpacing * 0.6
                let finalY = min(yAdjusted, lastRow.y - minGap)
                
                spawnRow(at: finalY)
                lastRowY = finalY
            }
        }

        // 4. Power-Up & Collectible Spawning Logic
        // In Story Mode: spawn 3 Memory Shards at 25%, 50%, and 75% of level target
        if gameMode == .story {
            let target = selectedLevel * 1000
            let shardInterval = target / 4
            
            if score > 0 && score % shardInterval < 2 && powerUp == nil {
                let shardIndex = min(score / shardInterval, 3)
                if shardIndex >= 1 && shardIndex <= 3 {
                    spawnMemoryShard(size: gameSize, shardIndex: shardIndex)
                }
            }
        }
        
        // Spawn standard power-up periodically
        if score > 0 && score % 220 == 0 && powerUp == nil {
            let levelInfo = GameLevelInfo.info(for: selectedLevel)
            let canSpawnMultiplier = gameMode == .endless || levelInfo.allowsScoreMultiplier
            let rand = Double.random(in: 0...1)
            if rand < 0.35 && canSpawnMultiplier {
                spawnScoreMultiplierPowerUp(size: gameSize)
            } else if rand < 0.65 {
                spawnPowerUp(size: gameSize) // Shield
            } else {
                spawnEnergyCell(size: gameSize) // Dash Recharge
            }
        }
        
        // Spawn rare revive heart in endless mode
        if gameMode == .endless && score > 0 && score % 2500 == 0 && powerUp == nil {
            spawnRevivePowerUp(size: gameSize)
        }

        // 5. Score Progression
        let basePoints = multiplierActive ? 2 : 1
        score += basePoints
        
        if multiplierActive {
            multiplierTimer -= 1
            if multiplierTimer <= 0 {
                multiplierActive = false
            }
        }
        
        // 6. Level Progression (Story Mode)
        if gameMode == .story {
            let target = selectedLevel * 1000
            
            // Trigger finish line Synapse Gateway when within 130 points of target
            if score >= target - 130 && !isApproachingGate && !isPassingGate && !levelComplete && !gameWon {
                isApproachingGate = true
                gateY = -140
                AudioHapticManager.shared.playSuccessHaptic()
            }
            
            // Strictly cap score at level target in Story Mode so it never overshoots
            if score > target {
                score = target
            }
        }
    }
    
    // MARK: - Level Finish Gateway Sequence
    func updateGate(size: CGSize, dt: CGFloat) {
        guard gameMode == .story && isApproachingGate else { return }
        
        let playerY = size.height - 60
        let totalDistance = max(playerY - (-140), 400)
        
        // Dynamic descent: arrives smoothly in ~2.0 seconds (120 frames at 60fps)
        var speedMultiplier: CGFloat = 1.0
        
        // If target score is reached, fast-track the gateway so the player doesn't wait
        let target = selectedLevel * 1000
        if score >= target {
            speedMultiplier = 2.8
        }
        
        let dashMultiplier: CGFloat = isDashing ? 2.0 : 1.0
        let descentSpeed = (totalDistance / 120.0) * speedMultiplier * (dt * 60.0) * dashMultiplier
        gateY += descentSpeed
        
        // OBSTACLE SPLIT: lerp obstacles sideways as gate approaches
        let splitTarget = gameWidth * 0.62
        if !isPassingGate && splitObstaclesOffset < splitTarget {
            splitObstaclesOffset += (splitTarget - splitObstaclesOffset) * 0.09
        }
        
        // When gateway reaches player position: trigger warp pass!
        if !isPassingGate && gateY >= playerY - 35 {
            triggerGatePassSequence(size: size)
        }
        
        // Safety: if gate somehow went past without triggering
        if !isPassingGate && gateY >= size.height + 20 {
            triggerGatePassSequence(size: size)
        }
    }
    
    func triggerGatePassSequence(size: CGSize) {
        guard !isPassingGate else { return }
        isPassingGate = true
        isInvincible = true
        
        // Ensure final score in story mode matches target exactly
        if gameMode == .story {
            score = selectedLevel * 1000
        }
        
        // 1. Clear obstacles so player has a clean victory transition
        obstacleRows.removeAll()
        powerUp = nil
        
        // 2. Center the player into the gateway beam
        withAnimation(.easeInOut(duration: 0.45)) {
            playerX = 0
        }
        
        // 3. Sensory feedback
        AudioHapticManager.shared.playSuccessHaptic()
        AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
        triggerScreenShake(intensity: 4.0)
        
        // 4. White warp flash bloom
        withAnimation(.easeIn(duration: 0.35)) {
            victoryFlashOpacity = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            withAnimation(.easeOut(duration: 0.75)) {
                self?.victoryFlashOpacity = 0.0
            }
        }
        
        // 5. Smoothly present completion modal AFTER the victory sequence completes!
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) { [weak self] in
            guard let self = self else { return }
            
            if self.selectedLevel < 30 {
                self.levelComplete = true
                if self.unlockedLevels < self.selectedLevel + 1 {
                    self.unlockedLevels = self.selectedLevel + 1
                }
            } else {
                self.gameWon = true
            }
        }
    }
    
    // MARK: - TOUGHNESS: Synaptic Dash Trigger
    func performDash() {
        guard alive && !isPaused && !isDashing && StoreManager.shared.dashCount > 0 else { return }
        
        guard StoreManager.shared.useDash() else { return }
        isDashing = true
        dashTimer = 0.42 // 420ms of phase-through & warp surge
        
        AudioHapticManager.shared.playDashHaptic()
        AudioHapticManager.shared.playSound(named: "PowerUp")
        triggerScreenShake(intensity: 6.0)
    }
    
    // MARK: - TOUGHNESS: Near-Miss / Grazing Action
    func triggerNearMiss(at point: CGPoint) {
        guard alive && !isPaused && !isDashing else { return }
        
        nearMissStreak += 1
        let bonus = 30 * min(nearMissStreak, 5)
        score += bonus
        StoreManager.shared.balance += 5
        
        if gameMode == .story {
            let target = selectedLevel * 1000
            if score > target {
                score = target
            }
        }
        
        nearMissPosition = point
        nearMissText = "GRAZE! +\(bonus)"
        showNearMissToast = true
        
        AudioHapticManager.shared.playNearMissHaptic()
        triggerScreenShake(intensity: 2.5)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showNearMissToast = false
        }
    }
    
    // MARK: - MEANING: Collect Memory Shard
    func collectMemoryShard(shardIndex: Int, at point: CGPoint) {
        guard gameMode == .story else { return }
        levelShardsCollected += 1
        MemoryShardManager.shared.collectShard(level: selectedLevel, shardIndex: shardIndex)
        
        AudioHapticManager.shared.playShardHaptic()
        AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
        
        collisionPosition = point
        showCollisionEffect = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.showCollisionEffect = false
        }
    }
    
    func triggerScreenShake(intensity: CGFloat = 6.0) {
        withAnimation(.easeInOut(duration: 0.04)) {
            screenShakeOffset = intensity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) { [weak self] in
            withAnimation(.easeInOut(duration: 0.04)) {
                self?.screenShakeOffset = -intensity * 0.7
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) { [weak self] in
                withAnimation(.easeOut(duration: 0.04)) {
                    self?.screenShakeOffset = 0
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
        let minSpeed: CGFloat = 1.3
        let maxSpeed: CGFloat = 3.9
        let targetScore: CGFloat = 5000
        
        let progress = min(CGFloat(score) / targetScore, 1.0)
        let easedProgress = sqrt(progress)
        let levelMultiplier = CGFloat(selectedLevel - 1) * 0.04
        
        return minSpeed + (maxSpeed - minSpeed) * easedProgress + levelMultiplier
    }
    
    // Heart Rate Logic synced with patient vitals
    var heartRate: Int {
        let base = 65
        let intensity = Int(currentSpeed() * 18)
        let nearMissBonus = min(nearMissStreak * 4, 30)
        return min(base + intensity + nearMissBonus, 160)
    }
    
    func checkReviveAvailability() {
        if StoreManager.shared.reviveCount > 0 {
            showRevivePopup = true
        } else {
            alive = false
            triggerGameOverSequence()
        }
    }
    
    func revive() {
        useRevive()
    }
    
    func useRevive() {
        if StoreManager.shared.useRevive() {
            alive = true
            showRevivePopup = false
            shieldActive = true
            isInvincible = true
            dashEnergy = 1.0
            
            AudioHapticManager.shared.playSound(named: "PowerUp")
            AudioHapticManager.shared.playEnhancedPowerUp()
            
            startTimer()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.shieldActive = false
                self?.isInvincible = false
            }
        } else {
            skipRevive()
        }
    }
    
    func skipRevive() {
        showRevivePopup = false
        alive = false
        triggerGameOverSequence()
    }
    
    private func triggerGameOverSequence() {
        StoreManager.shared.balance += score
        
        if score > highScore {
            highScore = score
            showHighScoreBadge = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.restartAvailable = true
        }
    }
    
    func updateRows(size: CGSize, dt: CGFloat) {
        let dashMultiplier: CGFloat = isDashing ? 2.0 : 1.0
        let actualSpeed = currentSpeed() * (dt * 60.0) * dashMultiplier

        for rowIndex in obstacleRows.indices {
            obstacleRows[rowIndex].y += actualSpeed

            for obsIndex in obstacleRows[rowIndex].obstacles.indices {
                var obs = obstacleRows[rowIndex].obstacles[obsIndex]
                obs.y = obstacleRows[rowIndex].y

                // Update phase timer for glitch phasers
                if obs.type == .glitchPhaser {
                    obs.phaseTimer += Double(dt)
                }

                if obs.type == .moving {
                    let gapRange = obstacleRows[rowIndex].gapRange
                    let halfWidth = obs.width / 2

                    let minTrack: CGFloat
                    let maxTrack: CGFloat

                    if obs.x < (gapRange.lowerBound + gapRange.upperBound) / 2 {
                        // Left of gap
                        minTrack = -gameWidth / 2
                        maxTrack = gapRange.lowerBound
                    } else {
                        // Right of gap
                        minTrack = gapRange.upperBound
                        maxTrack = gameWidth / 2
                    }

                    let leftBound = minTrack + halfWidth
                    let rightBound = maxTrack - halfWidth

                    if rightBound > leftBound + 4 {
                        obs.x += obs.dx * (dt * 60.0)

                        if obs.x <= leftBound {
                            obs.x = leftBound
                            if obs.dx < 0 { obs.dx = abs(obs.dx) }
                        } else if obs.x >= rightBound {
                            obs.x = rightBound
                            if obs.dx > 0 { obs.dx = -abs(obs.dx) }
                        }
                    } else {
                        obs.x = (minTrack + maxTrack) / 2
                        obs.dx = 0
                        obs.type = .normal
                    }
                }

                obstacleRows[rowIndex].obstacles[obsIndex] = obs
            }
        }

        obstacleRows.removeAll { $0.y > size.height + 40 }
    }

    func updatePowerUp(size: CGSize, dt: CGFloat) {
        guard var pu = powerUp else { return }
        let dashMultiplier: CGFloat = isDashing ? 2.0 : 1.0
        let speed = currentSpeed() * (dt * 60.0) * dashMultiplier
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
