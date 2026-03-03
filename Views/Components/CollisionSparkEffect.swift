import SwiftUI

/// Collision spark effect - shows when ball hits obstacle
/// Represents "signal lost" with electrical spark animation
struct CollisionSparkEffect: View {
    @State private var isAnimating = false
    @State private var particles: [SparkParticle] = []
    
    var body: some View {
        ZStack {
            // Central flash
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, .red, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: isAnimating ? 60 : 20
                    )
                )
                .frame(width: 120, height: 120)
                .opacity(isAnimating ? 0 : 1)
            
            // Spark particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offset.width, y: particle.offset.height)
                    .opacity(particle.opacity)
            }
            
            // Signal lost text
            Text("SIGNAL LOST")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(.red)
                .opacity(isAnimating ? 0 : 1)
                .offset(y: -40)
        }
        .onAppear {
            // Generate spark particles
            particles = (0..<20).map { i in
                let angle = Double(i) * (360.0 / 20.0) * .pi / 180.0
                let distance: CGFloat = CGFloat.random(in: 30...60)
                return SparkParticle(
                    angle: angle,
                    distance: distance,
                    color: [.white, .yellow, .orange, .red].randomElement()!,
                    size: CGFloat.random(in: 3...8)
                )
            }
            
            // Animate
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
                // Animate particles outward
                for i in particles.indices {
                    let angle = particles[i].angle
                    let distance = particles[i].distance
                    particles[i].offset = CGSize(
                        width: cos(angle) * distance,
                        height: sin(angle) * distance
                    )
                    particles[i].opacity = 0
                }
            }
        }
    }
}

struct SparkParticle: Identifiable {
    let id = UUID()
    var angle: Double
    var distance: CGFloat
    var color: Color
    var size: CGFloat
    var offset: CGSize = .zero
    var opacity: Double = 1.0
}
