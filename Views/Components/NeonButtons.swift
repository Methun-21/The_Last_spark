import SwiftUI

struct NeonCapsuleButton: View {
    var title: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(color)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .stroke(color, lineWidth: 2)
                        .shadow(color: color.opacity(0.8), radius: 8)
                )
                .shadow(color: color.opacity(0.4), radius: 4)
        }
    }
}

struct NeonOrbButton: View {
    var onTap: () -> Void
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 70, height: 70)
                .blur(radius: 10)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.6 : 0.3)
            
            // Outer Ring
            Circle()
                .stroke(LinearGradient(colors: [.cyan, .white], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                .frame(width: 80, height: 80)
                .shadow(color: .cyan, radius: 10)
            
            // Inner Squiggle/Logo
            Image(systemName: "play.fill")
                .font(.title)
                .foregroundStyle(.white)
                .shadow(color: .white, radius: 5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .onTapGesture {
            AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
            onTap()
        }
    }
}
