import SwiftUI

extension GameViewModel {
    func checkCollisions(size: CGSize) {
        // Layout safety check - ignore collisions if GeometryReader hasn't loaded sizes yet
        if size.width < 10 || size.height < 10 { return }
        
        // Invincibility check - Ignore all collisions if invincible
        if isInvincible { return }
        
        let px = playerX + size.width/2
        let py = size.height - 60

        // EDGE BOUNDARY COLLISION
        // Apple-quality feel: Visual radius is 28, but we allow a slight overhang (tolerance)
        // so it doesn't feel like you died "too early" when touching the wall.
        let visualRadius: CGFloat = 28.0
        let edgeTolerance: CGFloat = 4.0 // Increased slightly for better feel
        let leftEdge = -gameWidth/2 + visualRadius - edgeTolerance
        let rightEdge = gameWidth/2 - visualRadius + edgeTolerance
        
        if playerX <= leftEdge || playerX >= rightEdge {
            // Hit the edge - COLLISION
            collisionPosition = CGPoint(x: px, y: py)
            showCollisionEffect = true
            
            AudioHapticManager.shared.playSound(named: "GameOver")
            AudioHapticManager.shared.playEnhancedCollision()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showCollisionEffect = false
            }
            
            // Trigger Revive/Death Flow
            checkReviveAvailability()
            return
        }

        // OBSTACLE COLLISION
        // 1. Power-Ups
        let playerCollisionRadius: CGFloat = 22.0 // ~80% of visual size
        
        if let pu = powerUp {
            let distance = hypot((px - (pu.x + size.width/2)), (py - pu.y))
            if distance < playerCollisionRadius + 15 { 
                switch pu.type {
                case .scoreMultiplier:
                    multiplierActive = true
                    multiplierTimer = 300
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

                default: // Shield
                    shieldActive = true
                    powerUp = nil
                    AudioHapticManager.shared.playSound(named: "PowerUp")
                    AudioHapticManager.shared.playEnhancedPowerUp()
                    return
                }
            }
        }

        // 2. Obstacles
        let obstacleHalfHeight: CGFloat = 7.2
        
        // If Shield is Active
        if shieldActive {
            outerLoop: for rowIndex in obstacleRows.indices {
                for obsIndex in obstacleRows[rowIndex].obstacles.indices {
                    let obs = obstacleRows[rowIndex].obstacles[obsIndex]
                    
                    let effectiveWidth = obs.width
                    let left = obs.x + size.width/2 - effectiveWidth/2
                    let right = obs.x + size.width/2 + effectiveWidth/2
                    let top = obs.y - obstacleHalfHeight
                    let bottom = obs.y + obstacleHalfHeight
                    
                    if px + playerCollisionRadius > left && px - playerCollisionRadius < right && py + playerCollisionRadius > top && py - playerCollisionRadius < bottom {
                        // Shield Break Mechanism
                        shieldActive = false
                        
                        // Visual feedback - remove the hit obstacle
                        if obstacleRows.indices.contains(rowIndex) && obstacleRows[rowIndex].obstacles.indices.contains(obsIndex) {
                            obstacleRows[rowIndex].obstacles.remove(at: obsIndex)
                        }
                        
                        AudioHapticManager.shared.playSound(named: "PowerUp")
                        AudioHapticManager.shared.playEnhancedPowerUp()
                        
                        // Brief invincibility after shield break?
                        // For now, just break loop
                        break outerLoop
                    }
                }
            }
            return
        }
        
        // Normal Collision (No Shield)
        outerLoop: for rowIndex in obstacleRows.indices {
            for obsIndex in obstacleRows[rowIndex].obstacles.indices {
                let obs = obstacleRows[rowIndex].obstacles[obsIndex]
                
                let effectiveWidth = obs.width
                
                let left = obs.x + size.width/2 - effectiveWidth/2
                let right = obs.x + size.width/2 + effectiveWidth/2
                let top = obs.y - obstacleHalfHeight
                let bottom = obs.y + obstacleHalfHeight
                
                // Check if player CORE is INSIDE obstacle
                if px + playerCollisionRadius > left && px - playerCollisionRadius < right && py + playerCollisionRadius > top && py - playerCollisionRadius < bottom {
                    // COLLISION
                    collisionPosition = CGPoint(x: px, y: py)
                    showCollisionEffect = true
                    
                    AudioHapticManager.shared.playHaptic(intensity: 1.0)
                    AudioHapticManager.shared.playSound(named: "GameOver")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.showCollisionEffect = false
                    }
                    
                    // Trigger Revive/Death Flow
                    checkReviveAvailability()
                    return
                }
            }
        }
    }
}
