import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var speed: Double
    var size: Double
    var opacity: Double
}

struct AtmosphericBackground: View {
    @State private var particles: [Particle] = []
    @State private var touchLocation: CGPoint = .zero
    @State private var isTouching = false
    
    @ObservedObject var storeManager = StoreManager.shared
    
    var body: some View {
        ZStack {
            // Deep Space Gradient (Theme Aware)
            storeManager.getGradient(for: storeManager.selectedBackgroundID)
                .ignoresSafeArea()
            
            // Interactive Particle System
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    
                    for particle in particles {
                        // Base Movement (falling/floating)
                        let yBase = (particle.y + time * particle.speed).truncatingRemainder(dividingBy: size.height)
                        let xBase = particle.x
                        
                        // Interaction Logic
                        var currentX = xBase
                        var currentY = yBase
                        
                        if isTouching {
                            let dx = currentX - touchLocation.x
                            let dy = currentY - touchLocation.y
                            let distance = sqrt(dx*dx + dy*dy)
                            let influenceRadius: Double = 150.0
                            
                            if distance < influenceRadius {
                                // Push away gently
                                let force = (influenceRadius - distance) / influenceRadius
                                currentX += dx * force * 0.5
                                currentY += dy * force * 0.5
                            }
                        }
                        
                        // Twinkle effect
                        let twinkle = (sin(time * particle.speed * 0.5) + 1.0) / 2.0 * 0.5 + 0.2
                        
                        let rect = CGRect(x: currentX, y: currentY, width: particle.size, height: particle.size)
                        context.opacity = twinkle
                        context.fill(Path(ellipseIn: rect), with: .color(.white))
                    }
                }
            }
            .opacity(0.8)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        touchLocation = value.location
                        withAnimation {
                            isTouching = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 1.0)) {
                            isTouching = false
                        }
                    }
            )
        }
        .onAppear {
            if particles.isEmpty {
                // Initialize 80 particles
                for _ in 0..<80 {
                    particles.append(Particle(
                        x: Double.random(in: 0...1000),
                        y: Double.random(in: 0...1000),
                        speed: Double.random(in: 10...40),
                        size: Double.random(in: 1...3),
                        opacity: Double.random(in: 0.2...0.7)
                    ))
                }
            }
        }
    }
}
