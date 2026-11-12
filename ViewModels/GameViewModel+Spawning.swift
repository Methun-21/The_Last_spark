import SwiftUI

extension GameViewModel {
    
    // MARK: - ROW SPAWNING LOGIC
    
    // Increased gap width for better horizontal spacing
    var minEscapeGapWidth: CGFloat { playerRadius * 2.4 }
    
    enum Phase {
        case easy, medium, hard
    }

    func spawnRow(at y: CGFloat) {
        // Extended phase logic for endless mode (no cap)
        let phase: Phase = {
            if score <= 1000 { return .easy }
            else if score <= 2000 { return .medium }
            else { return .hard } // Hard phase continues forever
        }()

        // CONTINUOUS SCALING for gap width (no 3000 cap)
        // Gap gets tighter as score increases, with diminishing returns
        let gapWidth: CGFloat = {
            let targetScore: CGFloat = 5000 // Reach minimum gap at 5000
            let maxGapMultiplier: CGFloat = 4.5 // Wide gaps at start
            let minGapMultiplier: CGFloat = 2.1 // Tight gaps at high scores
            
            // Logarithmic scaling for smooth difficulty curve
            let progress = min(CGFloat(score) / targetScore, 1.0)
            let easedProgress = sqrt(progress) // Square root for smooth curve
            let multiplier = maxGapMultiplier - (maxGapMultiplier - minGapMultiplier) * easedProgress
            return playerRadius * multiplier
        }()

        let leftEdge = -gameWidth/2
        let rightEdge = gameWidth/2

        let gapLeftMin = leftEdge
        let gapLeftMax = rightEdge - gapWidth
        let gapLeft: CGFloat
        if gapLeftMax >= gapLeftMin {
            gapLeft = CGFloat.random(in: gapLeftMin...gapLeftMax)
        } else {
            gapLeft = gapLeftMin
        }
        let gapRange = gapLeft...(gapLeft + gapWidth)

        var obstaclesInRow: [Obstacle] = []

        func createObstaclesForSegment(startX: CGFloat, endX: CGFloat, phase: Phase, isLeftSegment: Bool) -> [Obstacle] {
            let clampedStartX: CGFloat
            let clampedEndX: CGFloat
            
            if isLeftSegment {
                clampedStartX = max(startX, -gameWidth/2)
                clampedEndX = min(endX, gapRange.lowerBound)
            } else {
                clampedStartX = max(startX, gapRange.upperBound)
                clampedEndX = min(endX, gameWidth/2)
            }
            
            let segmentWidth = clampedEndX - clampedStartX
            
            if segmentWidth <= 0 {
                return []
            }
            
            switch phase {
            case .easy:
                let width = segmentWidth
                if width < 15 { return [] } // Prevent invisible obstacles
                let centerX = clampedStartX + width / 2
                return [Obstacle(x: centerX, y: y, width: width, color: .pink, dx: 0, type: .normal)]

            case .medium:
                if segmentWidth > minEscapeGapWidth * 2 && Bool.random() {
                    let gapBetweenTwins = minEscapeGapWidth * 1.5
                    let maxTotalWidth = segmentWidth - gapBetweenTwins
                    
                    if maxTotalWidth <= 0 || (maxTotalWidth - minEscapeGapWidth) < minEscapeGapWidth {
                        let width = segmentWidth
                        if width > 15 {
                            let centerX = clampedStartX + width / 2
                            return [Obstacle(x: centerX, y: y, width: width, color: .cyan, dx: 0, type: .normal)]
                        } else {
                            return []
                        }
                    }
                    
                    let minWidth1 = minEscapeGapWidth
                    let maxWidth1 = maxTotalWidth - minEscapeGapWidth
                    if minWidth1 > maxWidth1 {
                        let width = segmentWidth
                        if width > 15 {
                            let centerX = clampedStartX + width / 2
                            return [Obstacle(x: centerX, y: y, width: width, color: .cyan, dx: 0, type: .normal)]
                        } else {
                            return []
                        }
                    }
                    let width1 = CGFloat.random(in: minWidth1...maxWidth1)
                    let width2 = maxTotalWidth - width1
                    let colorSet = [Color.pink, Color.cyan, Color.green, Color.orange, Color.blue]
                    let color1 = colorSet.randomElement()!
                    let color2 = colorSet.randomElement()!
                    
                    var result: [Obstacle] = []
                    if width1 >= 15 {
                         result.append(Obstacle(x: clampedStartX + width1 / 2, y: y, width: width1, color: color1, dx: 0, type: .normal))
                    }
                    if width2 >= 15 {
                        result.append(Obstacle(x: clampedStartX + width1 + gapBetweenTwins + width2 / 2, y: y, width: width2, color: color2, dx: 0, type: .normal))
                    }
                    return result

                } else {
                    let color = [Color.pink, Color.cyan, Color.green, Color.orange, Color.blue].randomElement()!
                    let isGlitch = (selectedLevel >= 13 || score >= 1800) && Bool.random() && Bool.random()
                    let canMove = segmentWidth >= minEscapeGapWidth + 40 && Bool.random()
                    
                    if isGlitch {
                        let width = segmentWidth
                        if width < 15 { return [] }
                        let centerX = isLeftSegment ? gapRange.lowerBound - (width / 2) : gapRange.upperBound + (width / 2)
                        return [Obstacle(x: centerX, y: y, width: width, color: .red, dx: 0, type: .glitchPhaser)]
                    } else if canMove {
                        // Smooth moving dash: patrol 55% width with plenty of clear track
                        let obsWidth = max(segmentWidth * 0.55, 35)
                        let minTrack = clampedStartX + obsWidth / 2
                        let maxTrack = clampedEndX - obsWidth / 2
                        let centerX = (minTrack + maxTrack) / 2
                        let speed: CGFloat = CGFloat.random(in: 1.2...2.2)
                        let dx = speed * (Bool.random() ? 1 : -1)
                        return [Obstacle(x: centerX, y: y, width: obsWidth, color: color, dx: dx, type: .moving)]
                    } else {
                        let width = segmentWidth
                        if width < 15 { return [] }
                        let centerX = isLeftSegment ? gapRange.lowerBound - (width / 2) : gapRange.upperBound + (width / 2)
                        return [Obstacle(x: centerX, y: y, width: width, color: color, dx: 0, type: .normal)]
                    }
                }

            case .hard:
                if segmentWidth > minEscapeGapWidth * 2 && Int.random(in: 0..<3) == 0 {
                    let gapBetweenTwins = minEscapeGapWidth * 1.3
                    let maxTotalWidth = segmentWidth - gapBetweenTwins
                    
                    if maxTotalWidth <= 0 || (maxTotalWidth - minEscapeGapWidth) < minEscapeGapWidth {
                        let width = segmentWidth
                        if width > 15 {
                            let centerX = clampedStartX + width / 2
                            return [Obstacle(x: centerX, y: y, width: width, color: .orange, dx: 0, type: .normal)]
                        } else {
                            return []
                        }
                    }
                    
                    let minWidth1 = minEscapeGapWidth
                    let maxWidth1 = maxTotalWidth - minEscapeGapWidth
                    if minWidth1 > maxWidth1 {
                        let width = segmentWidth
                        if width > 15 {
                            let centerX = clampedStartX + width / 2
                            return [Obstacle(x: centerX, y: y, width: width, color: .orange, dx: 0, type: .normal)]
                        } else {
                            return []
                        }
                    }
                    let width1 = CGFloat.random(in: minWidth1...maxWidth1)
                    let width2 = maxTotalWidth - width1
                    let colorSet = [Color.pink, Color.cyan, Color.green, Color.orange, Color.blue]
                    let color1 = colorSet.randomElement()!
                    let color2 = colorSet.randomElement()!

                    var result: [Obstacle] = []
                    if width1 >= 15 {
                        result.append(Obstacle(x: clampedStartX + width1 / 2, y: y, width: width1, color: color1, dx: 0, type: .normal))
                    }
                    if width2 >= 15 {
                         result.append(Obstacle(x: clampedStartX + width1 + gapBetweenTwins + width2 / 2, y: y, width: width2, color: color2, dx: 0, type: .normal))
                    }
                    return result

                } else {
                    let color = [Color.pink, Color.cyan, Color.green, Color.orange, Color.blue].randomElement()!
                    let canMove = segmentWidth >= minEscapeGapWidth + 40 && Int.random(in: 0..<3) != 0
                    
                    if canMove {
                        let obsWidth = max(segmentWidth * 0.55, 35)
                        let minTrack = clampedStartX + obsWidth / 2
                        let maxTrack = clampedEndX - obsWidth / 2
                        let centerX = (minTrack + maxTrack) / 2
                        let speed: CGFloat = CGFloat.random(in: 1.6...2.6)
                        let dx = speed * (Bool.random() ? 1 : -1)
                        return [Obstacle(x: centerX, y: y, width: obsWidth, color: color, dx: dx, type: .moving)]
                    } else {
                        let width = segmentWidth
                        if width < 15 { return [] }
                        let centerX = isLeftSegment ? gapRange.lowerBound - (width / 2) : gapRange.upperBound + (width / 2)
                        return [Obstacle(x: centerX, y: y, width: width, color: color, dx: 0, type: .normal)]
                    }
                }
            }
        }

        let leftSegmentObstacles = createObstaclesForSegment(startX: leftEdge, endX: gapRange.lowerBound, phase: phase, isLeftSegment: true)
        let rightSegmentObstacles = createObstaclesForSegment(startX: gapRange.upperBound, endX: rightEdge, phase: phase, isLeftSegment: false)

        obstaclesInRow.append(contentsOf: leftSegmentObstacles)
        obstaclesInRow.append(contentsOf: rightSegmentObstacles)

        var rowDx: CGFloat = 0
        var rowMovingDirection: CGFloat = 1
        if phase == .easy {
            rowDx = 0
        } else {
            rowDx = currentSpeed() / 3
            rowMovingDirection = Bool.random() ? 1 : -1
        }

        var finalObstacles: [Obstacle] = []
        for obs in obstaclesInRow {
            finalObstacles.append(obs)
        }

        let row = ObstacleRow(y: y, obstacles: finalObstacles, gapRange: gapRange)
        obstacleRows.append(row)
    }
    
    // MARK: - SAFE POWER-UP & COLLECTIBLE SPAWNING
    // Guarantees power-ups spawn midway between obstacle rows in clear space,
    // aligned with the navigable gap so they NEVER merge or overlap with obstacle dashes!
    func spawnPowerUpEntity(type: Obstacle.ObstacleType, color: Color, shardIndex: Int = 0) {
        let diameter: CGFloat = 36
        let halfDiameter = diameter / 2
        
        // Find highest obstacle row (smallest Y, above or near screen top)
        let topRow = obstacleRows.min(by: { $0.y < $1.y })
        
        let spawnY: CGFloat
        let spawnX: CGFloat
        
        if let row = topRow {
            // Place vertically midway between this row and the row above it
            // rowSpacing is 130...220pt, so rowSpacing * 0.5 gives 65...110pt of clear space
            spawnY = row.y - (rowSpacing * 0.5)
            
            // Align with the gap so player can collect it cleanly
            let gapCenter = (row.gapRange.lowerBound + row.gapRange.upperBound) / 2
            let minX = -gameWidth / 2 + halfDiameter + 15
            let maxX = gameWidth / 2 - halfDiameter - 15
            
            if type == .memoryShard {
                let offset = CGFloat.random(in: -20...20)
                spawnX = min(max(gapCenter + offset, minX), maxX)
            } else {
                spawnX = min(max(gapCenter, minX), maxX)
            }
        } else {
            spawnY = -diameter - 40
            spawnX = CGFloat.random(in: (-gameWidth / 4)...(gameWidth / 4))
        }
        
        powerUp = Obstacle(x: spawnX, y: spawnY, width: diameter, color: color, type: type, shardIndex: shardIndex)
    }

    func spawnPowerUp(size: CGSize) {
        spawnPowerUpEntity(type: .shield, color: .green)
    }

    func spawnScoreMultiplierPowerUp(size: CGSize) {
        spawnPowerUpEntity(type: .scoreMultiplier, color: .purple)
    }
    
    func spawnRevivePowerUp(size: CGSize) {
        spawnPowerUpEntity(type: .revive, color: .pink)
    }
    
    func spawnEnergyCell(size: CGSize) {
        spawnPowerUpEntity(type: .energyCell, color: .cyan)
    }
    
    func spawnMemoryShard(size: CGSize, shardIndex: Int) {
        spawnPowerUpEntity(type: .memoryShard, color: .yellow, shardIndex: shardIndex)
    }
}
