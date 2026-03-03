import SwiftUI

struct SagaMapView: View {
    @ObservedObject var gameViewModel: GameViewModel
    var onLevelSelected: (Int) -> Void
    
    // Configuration
    let totalLevels = 30
    let pathHeight: CGFloat = 4000
    
    @State private var phase: CGFloat = 0
    @State private var pulse: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 1. Background (Deep Space / Mind)
            Color.black.opacity(0.8).ignoresSafeArea()
            
            // 2. Animated Neural Fog (Optional depth)
            
            // 3. Main Scrollable Map
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .top) {
                            
                            // A. The Neural Fiber (Base Glow)
                            NeuralPath(height: pathHeight)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .purple.opacity(0.4),
                                            .blue.opacity(0.4),
                                            .cyan.opacity(0.4),
                                            .purple.opacity(0.4)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                                )
                                .blur(radius: 10) // Soft backlit glow
                            
                            // B. The Active Signal (Bright Core with Gradient)
                            NeuralPath(height: pathHeight)
                                .stroke(
                                    LinearGradient(
                                        colors: [.purple, .cyan, .mint, .blue, .purple],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                                )
                                .shadow(color: .cyan, radius: 4)
                            
                            // C. The Electric Impulse (Flowing Animation)
                            NeuralPath(height: pathHeight)
                                .trim(from: 0, to: 1)
                                .stroke(
                                    LinearGradient(
                                        colors: [.clear, .white, .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    style: StrokeStyle(
                                        lineWidth: 3,
                                        lineCap: .round,
                                        lineJoin: .round,
                                        dash: [20, 40],
                                        dashPhase: phase
                                    )
                                )
                                .shadow(color: .white, radius: 5)
                            
                            // The Nodes
                            ForEach(1...totalLevels, id: \.self) { level in
                                let status = getLevelStatus(level)
                                let point = getPointForLevel(level, total: totalLevels, height: pathHeight)
                                
 
                                NeuralLevelNode(
                                    level: level,
                                    status: status,
                                    position: point,
                                    action: {
                                        if status != .locked {
                                            onLevelSelected(level)
                                        }
                                    }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: pathHeight)
                        .padding(.vertical, 100)
                        
                        // 4. The strict layout proxy layer. 
                        // This invisible stack exists solely so the ScrollView can map its IDs relative to the pathHeight consistently.
                        .background(
                            VStack(spacing: 0) {
                                // Since point.y is "height - (currentLevel * step)", level 30 is at the Top (0), level 1 is at the Bottom (height)
                                // We iterate backwards so level 30 is at the top of the VStack.
                                ForEach((1...totalLevels).reversed(), id: \.self) { level in
                                    Color.clear
                                        .frame(maxWidth: .infinity)
                                        .frame(height: pathHeight / CGFloat(totalLevels))
                                        .id(level) // Tags the level ID mathematically evenly across the background
                                }
                            }
                        )
                    }
                    .onAppear {
                        // Continuous Flow Animation
                        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                            phase -= 100 // Flow upwards
                        }
                        
                        // Scroll to highest unlocked level
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 1.5)) {
                                let targetLevel = min(gameViewModel.unlockedLevels, totalLevels)
                                proxy.scrollTo(targetLevel, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Logic to determine level status
    func getLevelStatus(_ level: Int) -> NeuralLevelNode.LevelStatus {
        if level < gameViewModel.selectedLevel {
            return .completed
        } else if level == gameViewModel.selectedLevel {
            return .unlocked
        } else {
            return level <= gameViewModel.unlockedLevels ? .unlocked : .locked
        }
    }
    
    // Organic Sine Wave Path Calculation
    func getPointForLevel(_ level: Int, total: Int, height: CGFloat) -> CGPoint {
        let normalizingFactor = 1.0 / CGFloat(total + 1)
        let y = height - (CGFloat(level) * normalizingFactor * height) // Bottom to Top
        
        // Complex smooth wave for more organic feel
        let screenWidth = UIScreen.main.bounds.width
        let normalizedLevel = Double(level) / Double(total)
        
        // Primary wave
        let xOffset1 = sin(Double(level) * 0.8) * (screenWidth * 0.3)
        // Secondary wave for organic irregularity
        let xOffset2 = cos(Double(level) * 0.4) * (screenWidth * 0.1)
        
        let x = (screenWidth / 2) + CGFloat(xOffset1 + xOffset2)
        
        return CGPoint(x: x, y: y)
    }
}

// The Winding Path Shape (Matches the node logic)
struct NeuralPath: Shape {
    let height: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let screenWidth = rect.width
        let totalPoints = 120 // High resolution for smoothness
        let stepY = height / CGFloat(totalPoints)
        
        // Mapping needs to match exactly 1..30 levels distributed over height
        // To match getPointForLevel exactly, we interpret 'i' as a fractional level
        
        let startPoint = CGPoint(x: screenWidth / 2, y: height) // Approximate start
        path.move(to: startPoint)
        
        for i in 0...totalPoints {
            let normalizedProgress = CGFloat(i) / CGFloat(totalPoints)
            let y = height - (normalizedProgress * height)
            
            // Map progress to level scale (1 to 30) for X calculation
            let equivalentLevel = normalizedProgress * 31 // 0 to 31
            
            let xOffset1 = sin(Double(equivalentLevel) * 0.8) * (screenWidth * 0.3)
            let xOffset2 = cos(Double(equivalentLevel) * 0.4) * (screenWidth * 0.1)
            let x = (screenWidth / 2) + CGFloat(xOffset1 + xOffset2)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}
