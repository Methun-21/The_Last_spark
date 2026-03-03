import SwiftUI

struct PlayerView: View {
    let skinColor: Color
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // 1. Particle Trail (Simulated with blur)
            Circle()
                .fill(skinColor.opacity(0.4))
                .frame(width: 40, height: 40)
                .blur(radius: 10)
                .offset(x: -5, y: 10) // Trail behind
            
            // 2. Outer Halo (Pulse)
            Circle()
                .stroke(skinColor.opacity(0.5), lineWidth: 2)
                .frame(width: 50, height: 50)
                .scaleEffect(isPulsing ? 1.2 : 0.8)
                .opacity(isPulsing ? 0 : 1)
                
            // 3. Core Orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, skinColor],
                        center: .center,
                        startRadius: 2,
                        endRadius: 25
                    )
                )
                .frame(width: 30, height: 30)
                .shadow(color: skinColor, radius: 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
