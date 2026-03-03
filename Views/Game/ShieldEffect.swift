import SwiftUI

// MARK: - New Shield Animation
struct ShieldEffect: View {
    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0
    @State private var pulse: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 1. Inner Tech Ring (Cyan) - Crisp dashed line
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.cyan, .white, .cyan]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .butt, dash: [5, 5])
                )
                .rotationEffect(.degrees(rotation1))
            
            // 2. Outer Protective Shell (Mint) - Thin solid line with gaps
            Circle()
                .stroke(
                    Color.mint.opacity(0.8),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [20, 20])
                )
                .rotationEffect(.degrees(-rotation2))
                .scaleEffect(1.1)
            
            // 3. Subtle Core Glow (Reduced Opacity)
            Circle()
                .fill(Color.cyan.opacity(0.15))
                .scaleEffect(pulse)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation1 = 360
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotation2 = 360
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = 1.05
            }
        }
    }
}
