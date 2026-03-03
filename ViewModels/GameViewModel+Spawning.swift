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
                    let gapBetweenTwins = minEscapeGapWidth * 1.7
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
                    
                    let twinsMoving = Bool.random() && Bool.random() && Bool.random()
                    var dx1: CGFloat = 0
                    var dx2: CGFloat = 0
                    var type: Obstacle.ObstacleType = .normal

                    if twinsMoving {
                        type = .moving
                        let sharedSpeed = CGFloat.random(in: 2...3)
                        let sharedDirection: CGFloat = Bool.random() ? 1 : -1
                        dx1 = sharedSpeed * sharedDirection
                        dx2 = sharedSpeed * sharedDirection
                    }

                    var result: [Obstacle] = []
                    if width1 >= 15 {
                         result.append(Obstacle(x: clampedStartX + width1 / 2, y: y, width: width1, color: color1, dx: dx1, type: type))
                    }
                    if width2 >= 15 {
                        result.append(Obstacle(x: clampedStartX + width1 + gapBetweenTwins + width2 / 2, y: y, width: width2, color: color2, dx: dx2, type: type))
                    }
                    return result

                } else {
                    let lowerBound = minEscapeGapWidth
                    let upperBound = segmentWidth
                    let width: CGFloat
                    if upperBound >= lowerBound {
                        width = CGFloat.random(in: lowerBound...upperBound)
                    } else {
                        if segmentWidth > 0 {
                            width = segmentWidth
                        } else {
                            return []
                        }
                    }
                    
                    let finalWidth = segmentWidth > 0 ? segmentWidth : width
                    if finalWidth < 15 { return [] }
                    
                    let centerX: CGFloat
                    if isLeftSegment {
                        centerX = gapRange.lowerBound - (finalWidth / 2)
                    } else {
                        centerX = gapRange.upperBound + (finalWidth / 2)
                    }
                    
                    let color = [Color.pink, Color.cyan, Color.green, Color.orange, Color.blue].randomElement()!
                    let isMoving = Bool.random()
                    var dx: CGFloat = 0
                    var type: Obstacle.ObstacleType = .normal
                    if isMoving {
                        dx = CGFloat.random(in: 2...3.5) * (Bool.random() ? 1 : -1)
                        type = .moving
                    }
                    return [Obstacle(x: centerX, y: y, width: finalWidth, color: color, dx: dx, type: type)]
                }

            case .hard:
                if segmentWidth > minEscapeGapWidth * 2 && Int.random(in: 0..<5) != 0 {
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
                    let twinsMoving = Int.random(in: 0..<5) != 0

                    var dx1: CGFloat = 0
                    var dx2: CGFloat = 0
                    var type: Obstacle.ObstacleType = .normal

                    if twinsMoving {
                        type = .moving
                        let sharedSpeed = CGFloat.random(in: 2.5...4)
                        let sharedDirection: CGFloat = Bool.random() ? 1 : -1
                        dx1 = sharedSpeed * sharedDirection
                        dx2 = sharedSpeed * sharedDirection
                    }

                    var result: [Obstacle] = []
                    if width1 >= 15 {
                        result.append(Obstacle(x: clampedStartX + width1 / 2, y: y, width: width1, color: color1, dx: dx1, type: type))
                    }
                    if width2 >= 15 {
                         result.append(Obstacle(x: clampedStartX + width1 + gapBetweenTwins + width2 / 2, y: y, width: width2, color: color2, dx: dx2, type: type))
                    }
                    return result

                } else {
                    let lowerBound = minEscapeGapWidth * 0.8
                    let upperBound = segmentWidth
                    let width: CGFloat
                    if upperBound >= lowerBound {
                        width = CGFloat.random(in: lowerBound...upperBound)
                    } else {
                        if segmentWidth > 0 {
                            return []
                        } else {
                            return []
                        }
                    }
                    
                    let finalWidth = segmentWidth > 0 ? segmentWidth : width
                    if finalWidth < 15 { return [] }
                    
                    let centerX: CGFloat
                    if isLeftSegment {
                        centerX = gapRange.lowerBound - (finalWidth / 2)
                    } else {
                        centerX = gapRange.upperBound + (finalWidth / 2)
                    }
                    
                    let color = [Color.pink, Color.cyan, Color.green, Color.orange, Color.blue].randomElement()!
                    let isMoving = (Int.random(in: 0..<4) != 0)
                    var dx: CGFloat = 0
                    var type: Obstacle.ObstacleType = .normal
                    if isMoving {
                        dx = CGFloat.random(in: 2.5...4) * (Bool.random() ? 1 : -1)
                        type = .moving
                    }
                    return [Obstacle(x: centerX, y: y, width: finalWidth, color: color, dx: dx, type: type)]
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
        for var obs in obstaclesInRow {
            if obs.type == .moving {
                obs.dx = rowDx * rowMovingDirection
            }
            finalObstacles.append(obs)
        }

        let row = ObstacleRow(y: y, obstacles: finalObstacles, gapRange: gapRange, movingDirection: rowMovingDirection, dx: rowDx)
        obstacleRows.append(row)
    }
    
    func spawnPowerUp(size: CGSize) {
        let diameter: CGFloat = 40
        let halfDiameter = diameter / 2
        let minX = -gameWidth/2 + halfDiameter
        let maxX = gameWidth/2 - halfDiameter

        let maxAttempts = 12
        var chosenX: CGFloat? = nil

        attemptLoop: for _ in 0..<maxAttempts {
            let x = CGFloat.random(in: minX...maxX)
            let y = -diameter

            let spawnY: CGFloat = y
            let margin: CGFloat = 40

            let relevantRows = obstacleRows.filter { abs($0.y - spawnY) < margin }
            var insideAnyGap = false
            for row in relevantRows {
                let gap = row.gapRange
                if x >= gap.lowerBound + halfDiameter && x <= gap.upperBound - halfDiameter {
                    insideAnyGap = true
                    break
                }
            }
            if insideAnyGap {
                continue attemptLoop
            }

            for row in relevantRows {
                for obs in row.obstacles {
                    let obsLeft = obs.x - obs.width / 2
                    let obsRight = obs.x + obs.width / 2
                    let obsTop = obs.y - 9
                    let obsBottom = obs.y + 9

                    let powerLeft = x - halfDiameter
                    let powerRight = x + halfDiameter
                    let powerTop = y - halfDiameter
                    let powerBottom = y + halfDiameter

                    let horizontalOverlap = powerRight > obsLeft && powerLeft < obsRight
                    let verticalOverlap = powerBottom > obsTop && powerTop < obsBottom

                    if horizontalOverlap && verticalOverlap {
                        continue attemptLoop
                    }
                }
            }

            chosenX = x
            break
        }

        guard let finalX = chosenX else { return }

        powerUp = Obstacle(x: finalX, y: -diameter, width: diameter, color: .green)
    }

    func spawnScoreMultiplierPowerUp(size: CGSize) {
        let diameter: CGFloat = 40
        let halfDiameter = diameter / 2
        let minX = -gameWidth/2 + halfDiameter
        let maxX = gameWidth/2 - halfDiameter

        let maxAttempts = 12
        var chosenX: CGFloat? = nil

        attemptLoop: for _ in 0..<maxAttempts {
            let x = CGFloat.random(in: minX...maxX)
            let y = -diameter

            let spawnY: CGFloat = y
            let margin: CGFloat = 40

            let relevantRows = obstacleRows.filter { abs($0.y - spawnY) < margin }
            var insideAnyGap = false
            for row in relevantRows {
                let gap = row.gapRange
                if x >= gap.lowerBound + halfDiameter && x <= gap.upperBound - halfDiameter {
                    insideAnyGap = true
                    break
                }
            }
            if insideAnyGap {
                continue attemptLoop
            }

            for row in relevantRows {
                for obs in row.obstacles {
                    let obsLeft = obs.x - obs.width / 2
                    let obsRight = obs.x + obs.width / 2
                    let obsTop = obs.y - 9
                    let obsBottom = obs.y + 9

                    let powerLeft = x - halfDiameter
                    let powerRight = x + halfDiameter
                    let powerTop = y - halfDiameter
                    let powerBottom = y + halfDiameter

                    let horizontalOverlap = powerRight > obsLeft && powerLeft < obsRight
                    let verticalOverlap = powerBottom > obsTop && powerTop < obsBottom

                    if horizontalOverlap && verticalOverlap {
                        continue attemptLoop
                    }
                }
            }

            chosenX = x
            break
        }

        guard let finalX = chosenX else { return }

        powerUp = Obstacle(x: finalX, y: -diameter, width: diameter, color: .purple, type: .scoreMultiplier)
    }
    
    func spawnRevivePowerUp(size: CGSize) {
        let diameter: CGFloat = 40
        let halfDiameter = diameter / 2
        let minX = -gameWidth/2 + halfDiameter
        let maxX = gameWidth/2 - halfDiameter

        let maxAttempts = 12
        var chosenX: CGFloat? = nil

        attemptLoop: for _ in 0..<maxAttempts {
            let x = CGFloat.random(in: minX...maxX)
            let y = -diameter

            let spawnY: CGFloat = y
            let margin: CGFloat = 40

            let relevantRows = obstacleRows.filter { abs($0.y - spawnY) < margin }
            var insideAnyGap = false
            for row in relevantRows {
                let gap = row.gapRange
                if x >= gap.lowerBound + halfDiameter && x <= gap.upperBound - halfDiameter {
                    insideAnyGap = true
                    break
                }
            }
            if insideAnyGap {
                continue attemptLoop
            }

            for row in relevantRows {
                for obs in row.obstacles {
                    let obsLeft = obs.x - obs.width / 2
                    let obsRight = obs.x + obs.width / 2
                    let obsTop = obs.y - 9
                    let obsBottom = obs.y + 9

                    let powerLeft = x - halfDiameter
                    let powerRight = x + halfDiameter
                    let powerTop = y - halfDiameter
                    let powerBottom = y + halfDiameter

                    let horizontalOverlap = powerRight > obsLeft && powerLeft < obsRight
                    let verticalOverlap = powerBottom > obsTop && powerTop < obsBottom

                    if horizontalOverlap && verticalOverlap {
                        continue attemptLoop
                    }
                }
            }

            chosenX = x
            break
        }

        guard let finalX = chosenX else { return }

        powerUp = Obstacle(x: finalX, y: -diameter, width: diameter, color: .pink, type: .revive)
    }
}
