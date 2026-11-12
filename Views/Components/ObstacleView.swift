import SwiftUI

struct ObstacleView: View {
    let width: CGFloat
    let height: CGFloat
    // Potential for future customization: let type: ObstacleType
    
    @State private var shimmer = false
    
    var body: some View {
        ZStack {
            // Base Shape (Memory Block)
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), Color.gray.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.3), radius: 5)
            
            // Glitch Line / Data Corruption
            Rectangle()
                .fill(Color.cyan.opacity(0.4))
                .frame(width: width * 0.8, height: 2)
                .offset(y: shimmer ? -height/2 : height/2)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmer = true
                    }
                }
        }
    }
}
