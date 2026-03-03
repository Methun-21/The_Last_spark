import SwiftUI

struct LiquidBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base Color
            Color.black.ignoresSafeArea()
            
            // Animated Orbs
            GeometryReader { geo in
                ZStack {
                    // Orb 1: Cyan/Blue
                    Circle()
                        .fill(Color.cyan.opacity(0.4))
                        .frame(width: geo.size.width * 0.8)
                        .blur(radius: 60)
                        .offset(x: animate ? -30 : 30, y: animate ? -30 : 30)
                        .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animate)
                    
                    // Orb 2: Purple/Pink
                    Circle()
                        .fill(Color.purple.opacity(0.4))
                        .frame(width: geo.size.width * 0.8)
                        .blur(radius: 60)
                        .offset(x: animate ? 50 : -50, y: animate ? 20 : -20)
                        .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)
                    
                    // Orb 3: Blue
                    Circle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: geo.size.width * 0.7)
                        .blur(radius: 50)
                        .offset(x: animate ? -20 : 60, y: animate ? 60 : -40)
                        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.black.opacity(0.3)) // Darken slightly
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}
