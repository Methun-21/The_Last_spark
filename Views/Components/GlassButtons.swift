import SwiftUI

struct GlassCapsuleButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
            action()
        }) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 5)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
}

struct GlassOrbButton: View {
    var icon: String = "play.fill"
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
            action()
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.5), radius: 5)
            }
        }
    }
}
