import SwiftUI

public struct Obstacle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var color: Color
    public var dx: CGFloat = 0 // Horizontal speed
    public var type: ObstacleType = .normal
    
    // Advanced mechanics states
    public var isGrazed: Bool = false // Tracks if near-miss was already awarded
    public var phaseTimer: Double = 0 // For glitch/pulsing cycles
    public var shardIndex: Int = 0   // For memory shard identifier (1, 2, 3)
    
    public enum ObstacleType: Equatable {
        case normal
        case moving
        case glitchPhaser    // Phases between solid and ethereal
        case pulseNode       // Expands and contracts with neural heartbeat
        case memoryShard     // Collectible golden narrative fragment
        case energyCell      // Instantly restores dash energy
        case scoreMultiplier // Purple/Golden - gives 2x points
        case revive          // Pink Heart - restores life
        case shield          // Protects against 1 impact
    }
    
    public init(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        color: Color,
        dx: CGFloat = 0,
        type: ObstacleType = .normal,
        shardIndex: Int = 0
    ) {
        self.x = x
        self.y = y
        self.width = width
        self.color = color
        self.dx = dx
        self.type = type
        self.shardIndex = shardIndex
    }
}

public struct ObstacleRow: Identifiable {
    public let id = UUID()
    public var y: CGFloat
    public var obstacles: [Obstacle]
    public var gapRange: ClosedRange<CGFloat> // Track where the gap is
    
    // Row-level movement
    public var movingDirection: CGFloat = 0 
    public var dx: CGFloat = 0
    
    public init(
        y: CGFloat,
        obstacles: [Obstacle],
        gapRange: ClosedRange<CGFloat>,
        movingDirection: CGFloat = 0,
        dx: CGFloat = 0
    ) {
        self.y = y
        self.obstacles = obstacles
        self.gapRange = gapRange
        self.movingDirection = movingDirection
        self.dx = dx
    }
}
