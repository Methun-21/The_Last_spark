import SwiftUI

struct ObstacleView: View {
    let width: CGFloat
    let height: CGFloat
    var type: Obstacle.ObstacleType = .normal
    var color: Color = .white
    
    @State private var shimmer = false
    @State private var glitchFlicker = false
    
    var body: some View {
        ZStack {
            if type == .glitchPhaser {
                // Glitch Phaser (Red / Ethereal Shift)
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(glitchFlicker ? 0.25 : 0.9), Color.pink.opacity(glitchFlicker ? 0.15 : 0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width, height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red.opacity(glitchFlicker ? 0.35 : 0.9), lineWidth: 1.5)
                    )
                    .shadow(color: .red.opacity(glitchFlicker ? 0.15 : 0.7), radius: 8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            glitchFlicker = true
                        }
                    }
            } else {
                // Standard & Moving Barriers
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.85), Color.black.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width, height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color.opacity(0.85), lineWidth: 1.2)
                    )
                    .shadow(color: color.opacity(0.45), radius: 6)
                
                // Neon Circuit Scanline
                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: max(width * 0.8, 10), height: 2)
                    .offset(y: shimmer ? -height / 2 + 2 : height / 2 - 2)
                    .onAppear {
                        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                            shimmer = true
                        }
                    }
                
                if type == .moving {
                    // Motion chevron indicators
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(width: max(width - 12, 10))
                }
            }
        }
    }
}
