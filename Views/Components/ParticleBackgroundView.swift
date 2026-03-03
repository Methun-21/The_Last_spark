import SwiftUI

struct ParticleBackgroundView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speedY: CGFloat
    }
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(x: particle.x * size.width, y: particle.y * size.height, width: particle.size, height: particle.size)
                context.opacity = particle.opacity
                context.fill(Path(ellipseIn: rect), with: .color(.yellow))
            }
        }
        .onReceive(timer) { _ in
            updateParticles()
        }
        .onAppear {
            // Initial burst
            for _ in 0..<50 {
                particles.append(createParticle())
            }
        }
        .ignoresSafeArea()
    }
    
    func createParticle() -> Particle {
        Particle(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 2...5),
            opacity: Double.random(in: 0.3...1.0),
            speedY: CGFloat.random(in: 0.001...0.005)
        )
    }
    
    func updateParticles() {
        for i in particles.indices {
            particles[i].y += particles[i].speedY
            if particles[i].y > 1.0 {
                particles[i].y = 0
                particles[i].x = CGFloat.random(in: 0...1)
            }
        }
    }
}
