import SwiftUI

struct NeuralLevelNode: View {
    let level: Int
    let status: LevelStatus
    let position: CGPoint
    let action: () -> Void
    
    enum LevelStatus {
        case locked
        case unlocked
        case completed
    }
    
    @State private var isPulsing = false
    @State private var rotation: Double = 0
    
    var sectorColor: Color {
        GameLevelInfo.info(for: level).sector.themeColor
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 1. Interactive Pulse (Unlocked only)
                if status == .unlocked {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [sectorColor, .white, sectorColor.opacity(0.3), sectorColor]),
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 75, height: 75)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .opacity(isPulsing ? 0 : 0.8)
                        .onAppear {
                            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                isPulsing = true
                            }
                        }
                }
                
                // 2. Node Core (Gradient Fill)
                Circle()
                    .fill(nodeGradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: glowColor.opacity(0.8), radius: status == .locked ? 0 : 15)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(status == .locked ? 0.2 : 0.8), lineWidth: 2)
                    )
                
                // 3. Icon / Text
                if status == .locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.4))
                } else {
                    Text("\(level)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1)
                }
                
                // 4. Completed Check / Stars
                if status == .completed {
                    Circle()
                        .stroke(Color.mint, lineWidth: 2)
                        .frame(width: 68, height: 68)
                        .opacity(0.6)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.mint)
                                .background(Circle().fill(.black))
                                .offset(x: 20, y: -20)
                        )
                }
            }
        }
        .disabled(status == .locked)
        .position(position)
    }
    
    var nodeGradient: LinearGradient {
        switch status {
        case .locked:
            return LinearGradient(colors: [Color.gray.opacity(0.3), Color.black.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .unlocked:
            return LinearGradient(colors: [sectorColor, sectorColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .completed:
            return LinearGradient(colors: [.mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var glowColor: Color {
        switch status {
        case .locked: return .clear
        case .unlocked: return sectorColor
        case .completed: return .mint
        }
    }
}
