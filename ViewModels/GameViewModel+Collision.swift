import SwiftUI

extension GameViewModel {
    func checkCollisions(size: CGSize) {
        // Layout safety check
        if size.width < 10 || size.height < 10 { return }
        
        let px = playerX + size.width / 2
        let py = size.height - 60
        let visualRadius: CGFloat = playerRadius
        let playerCollisionRadius: CGFloat = 20.0 // True hit core
        let grazeRadius: CGFloat = playerCollisionRadius + 15.0 // Near-miss zone

        // 1. EDGE BOUNDARY COLLISION
        let edgeTolerance: CGFloat = 6.0
        let leftEdge = -gameWidth / 2 + visualRadius - edgeTolerance
        let rightEdge = gameWidth / 2 - visualRadius + edgeTolerance
        
        if playerX <= leftEdge || playerX >= rightEdge {
            if !isInvincible && !isDashing {
                collisionPosition = CGPoint(x: px, y: py)
                showCollisionEffect = true
                triggerScreenShake(intensity: 8.0)
                
                AudioHapticManager.shared.playSound(named: "GameOver")
                AudioHapticManager.shared.playEnhancedCollision()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.showCollisionEffect = false
                }
                
                checkReviveAvailability()
                return
            }
        }

        // 2. POWER-UP & COLLECTIBLE PICKUP
        if let pu = powerUp {
            let puX = pu.x + size.width / 2
            let puY = pu.y
            let dist = hypot(px - puX, py - puY)
            
            if dist < playerCollisionRadius + 20 {
                switch pu.type {
                case .scoreMultiplier:
                    multiplierActive = true
                    multiplierTimer = 320
                    powerUp = nil
                    AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
                    AudioHapticManager.shared.playEnhancedPowerUp()
                    return
                    
                case .revive:
                    StoreManager.shared.reviveCount += 1
                    powerUp = nil
                    AudioHapticManager.shared.playSound(named: "PowerUp")
                    AudioHapticManager.shared.playEnhancedPowerUp()
                    return
                    
                case .energyCell:
                    StoreManager.shared.addDash(1)
                    powerUp = nil
                    AudioHapticManager.shared.playSound(named: "PowerUp")
                    AudioHapticManager.shared.playDashHaptic()
                    return
                    
                case .memoryShard:
                    collectMemoryShard(shardIndex: pu.shardIndex, at: CGPoint(x: puX, y: puY))
                    powerUp = nil
                    return
                    
                default: // Shield
                    shieldActive = true
                    powerUp = nil
                    AudioHapticManager.shared.playSound(named: "PowerUp")
                    AudioHapticManager.shared.playEnhancedPowerUp()
                    return
                }
            }
        }

        // 3. OBSTACLE COLLISION & NEAR-MISS DETECTION
        // Skip obstacle collisions entirely during the gate approach sequence —
        // obstacles are visually split away but their physics positions haven't moved.
        // The spark must be safe during the cinematic finish.
        if isApproachingGate { return }
        
        let obstacleHalfHeight: CGFloat = 8.5
        
        for rowIndex in obstacleRows.indices {
            for obsIndex in obstacleRows[rowIndex].obstacles.indices {
                var obs = obstacleRows[rowIndex].obstacles[obsIndex]
                
                // If it's a glitch phaser, check if it's currently in an ethereal/flickering state
                if obs.type == .glitchPhaser {
                    // Periodic phase: every 1.6s, transparent for 0.6s
                    let cycle = obs.phaseTimer.truncatingRemainder(dividingBy: 1.6)
                    if cycle < 0.65 {
                        // Passable / ethereal right now!
                        continue
                    }
                }
                
                let boxLeft = obs.x + size.width / 2 - obs.width / 2
                let boxRight = obs.x + size.width / 2 + obs.width / 2
                let boxTop = obs.y - obstacleHalfHeight
                let boxBottom = obs.y + obstacleHalfHeight
                
                // Clamped closest point on obstacle rectangle (True Circle-to-AABB)
                let closestX = max(boxLeft, min(px, boxRight))
                let closestY = max(boxTop, min(py, boxBottom))
                
                let dx = px - closestX
                let dy = py - closestY
                let distSq = dx * dx + dy * dy
                
                // A. HIT DETECTED
                if distSq < playerCollisionRadius * playerCollisionRadius {
                    // If DASHING: Spark phases straight through barriers!
                    if isDashing {
                        // Spark successfully phased through obstacle!
                        continue
                    }
                    
                    // If INVINCIBLE (post-revive / shield recovery)
                    if isInvincible {
                        continue
                    }
                    
                    // If SHIELD IS ACTIVE: Shield absorbs and shatters
                    if shieldActive {
                        shieldActive = false
                        isInvincible = true // Brief 0.4s grace period to avoid double clip
                        triggerScreenShake(intensity: 5.0)
                        
                        // Shatter the hit obstacle
                        if obstacleRows.indices.contains(rowIndex) && obstacleRows[rowIndex].obstacles.indices.contains(obsIndex) {
                            obstacleRows[rowIndex].obstacles.remove(at: obsIndex)
                        }
                        
                        // Shield shatter spark effect
                        collisionPosition = CGPoint(x: closestX, y: closestY)
                        showCollisionEffect = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                            self?.showCollisionEffect = false
                        }
                        
                        AudioHapticManager.shared.playSound(named: "PowerUp")
                        AudioHapticManager.shared.playEnhancedCollision()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                            self?.isInvincible = false
                        }
                        return
                    }
                    
                    // FATAL COLLISION
                    collisionPosition = CGPoint(x: closestX, y: closestY)
                    showCollisionEffect = true
                    triggerScreenShake(intensity: 10.0)
                    
                    AudioHapticManager.shared.playSound(named: "GameOver")
                    AudioHapticManager.shared.playEnhancedCollision()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.showCollisionEffect = false
                    }
                    
                    checkReviveAvailability()
                    return
                }
                
                // B. NEAR-MISS / GRAZING DETECTED (TOUGHNESS BONUS)
                if distSq < grazeRadius * grazeRadius && !obs.isGrazed && !isDashing && alive {
                    obs.isGrazed = true
                    obstacleRows[rowIndex].obstacles[obsIndex] = obs
                    triggerNearMiss(at: CGPoint(x: closestX, y: closestY))
                }
            }
        }
    }
}
