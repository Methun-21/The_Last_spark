import SwiftUI

struct PlayerView: View {
    let skinColor: Color
    var isDashing: Bool = false
    var isInvincible: Bool = false
    
    @State private var isPulsing = false
    @State private var spinAngle: Double = 0
    @State private var invincibleBlink = false
    
    var body: some View {
        ZStack {
            // 1. Dash Warp Wave (Only when dashing)
            if isDashing {
                Circle()
                    .stroke(
                        LinearGradient(colors: [.white, skinColor, .clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: 3
                    )
                    .frame(width: 65, height: 65)
                    .scaleEffect(1.3)
                    .blur(radius: 2)
                
                // Ghost trail
                Circle()
                    .fill(skinColor.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .offset(y: 18)
                    .blur(radius: 6)
            }
            
            // 2. Particle Trail (Behind Spark)
            Circle()
                .fill(skinColor.opacity(0.45))
                .frame(width: 42, height: 42)
                .blur(radius: 10)
                .offset(y: 12)
            
            // 3. Outer Halo (Pulse & Rotation)
            Circle()
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [.white, skinColor, .white.opacity(0.3), skinColor]), center: .center),
                    lineWidth: 2
                )
                .frame(width: isDashing ? 56 : 48, height: isDashing ? 56 : 48)
                .rotationEffect(.degrees(spinAngle))
                .scaleEffect(isPulsing ? 1.15 : 0.9)
                .opacity(isPulsing ? 0.3 : 0.9)
                
            // 4. Core Orb (Ultra Bright Hotspot)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, skinColor],
                        center: .center,
                        startRadius: 2,
                        endRadius: isDashing ? 26 : 20
                    )
                )
                .frame(width: isDashing ? 36 : 28, height: isDashing ? 36 : 28)
                .shadow(color: skinColor, radius: isDashing ? 18 : 10)
                .shadow(color: .white, radius: 5)
        }
        .opacity(isInvincible ? (invincibleBlink ? 0.35 : 0.85) : 1.0)
        .onChange(of: isInvincible) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                    invincibleBlink = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.1)) {
                    invincibleBlink = false
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                spinAngle = 360
            }
        }
    }
}
