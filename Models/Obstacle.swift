import SwiftUI

public struct Obstacle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var color: Color
    public var dx: CGFloat = 0 // Horizontal speed
    public var type: ObstacleType = .normal
    
    public enum ObstacleType {
        case normal
        case moving
        case scoreMultiplier // Purple/Golden - gives 2x points for 5s
        case revive // Pink Heart - restores 1 life
    }
    
    public init(x: CGFloat, y: CGFloat, width: CGFloat, color: Color, dx: CGFloat = 0, type: ObstacleType = .normal) {
        self.x = x
        self.y = y
        self.width = width
        self.color = color
        self.dx = dx
        self.type = type
    }
}

public struct ObstacleRow: Identifiable {
    public let id = UUID()
    public var y: CGFloat
    public var obstacles: [Obstacle]
    public var gapRange: ClosedRange<CGFloat> // Track where the gap is
    
    // Row-level movement (e.g. whole row sways)
    public var movingDirection: CGFloat = 0 
    public var dx: CGFloat = 0
    
    public init(y: CGFloat, obstacles: [Obstacle], gapRange: ClosedRange<CGFloat>, movingDirection: CGFloat = 0, dx: CGFloat = 0) {
        self.y = y
        self.obstacles = obstacles
        self.gapRange = gapRange
        self.movingDirection = movingDirection
        self.dx = dx
    }
}
