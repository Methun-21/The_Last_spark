import SwiftUI

struct BentoCard<Content: View>: View {
    var content: Content
    var padding: CGFloat = 16
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0.05), .white.opacity(0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05), .white.opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.2))
                        .clipShape(Circle())
                    
                    Spacer()
                }
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 120)
    }
}

struct ActionCard: View {
    var title: String
    var subtitle: String
    var icon: String
    var gradientColors: [Color]
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // Background Gradient
                LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(0.8)
                
                // Texture/Pattern (Optional - keeping clean for now)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.bottom, 20)
                    
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: gradientColors.first?.opacity(0.4) ?? .clear, radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
