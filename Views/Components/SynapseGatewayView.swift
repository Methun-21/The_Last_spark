import SwiftUI

struct SynapseGatewayView: View {
    let width: CGFloat
    let sectorColor: Color
    var isPassing: Bool = false
    
    @State private var energyPulse = false
    @State private var beamRotation: Double = 0
    @State private var rippleScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 1. Broad Radiant Background Bloom
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [sectorColor.opacity(isPassing ? 0.6 : 0.25), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: width * 0.5
                    )
                )
                .frame(width: width * 1.1, height: 90)
                .scaleEffect(rippleScale)
            
            // 2. Gateway Arch / Main Horizontal Energy Beam
            ZStack {
                // Glow line
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.clear, sectorColor.opacity(0.8), .white, sectorColor.opacity(0.8), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width, height: 14)
                    .blur(radius: 6)
                
                // Crisp laser beam
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [sectorColor.opacity(0.3), .white, sectorColor.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width - 10, height: 4)
                    .shadow(color: sectorColor, radius: 8)
                
                // Dash Frequency Ripple Lines
                HStack(spacing: 6) {
                    ForEach(0..<15) { i in
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 3, height: 3)
                            .scaleEffect(energyPulse ? 1.4 : 0.8)
                    }
                }
            }
            
            // 3. Left & Right Energy Pylons (Anchors)
            HStack {
                // Left Pylon
                pylon(isLeft: true)
                Spacer()
                // Right Pylon
                pylon(isLeft: false)
            }
            .frame(width: width + 24)
            
            // 4. Center Jump Beacon & Status Badge
            VStack(spacing: 3) {
                // Center Hex Beacon
                ZStack {
                    Circle()
                        .stroke(sectorColor, lineWidth: 2)
                        .frame(width: 38, height: 38)
                        .scaleEffect(energyPulse ? 1.15 : 0.95)
                    
                    Circle()
                        .fill(RadialGradient(colors: [.white, sectorColor], center: .center, startRadius: 2, endRadius: 16))
                        .frame(width: 22, height: 22)
                        .shadow(color: sectorColor, radius: 10)
                    
                    Image(systemName: "arrow.down")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.black)
                }
                
                // Badge Label
                Text("✦ SYNAPSE GATEWAY ✦")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(sectorColor, lineWidth: 1))
                    .shadow(color: sectorColor.opacity(0.8), radius: 6)
            }
            .offset(y: -6)
        }
        .frame(height: 70)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                energyPulse = true
                rippleScale = 1.15
            }
        }
    }
    
    @ViewBuilder
    func pylon(isLeft: Bool) -> some View {
        ZStack {
            // Pylon Aura
            Circle()
                .fill(sectorColor.opacity(0.3))
                .frame(width: 44, height: 44)
                .blur(radius: 6)
            
            // Outer Ring
            Circle()
                .stroke(
                    LinearGradient(colors: [.white, sectorColor], startPoint: .top, endPoint: .bottom),
                    lineWidth: 2
                )
                .frame(width: 32, height: 32)
                .scaleEffect(energyPulse ? 1.1 : 0.9)
            
            // Core
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .shadow(color: sectorColor, radius: 8)
            
            // Vertical Antenna
            Capsule()
                .fill(sectorColor)
                .frame(width: 4, height: 40)
                .offset(y: isLeft ? -10 : 10)
        }
    }
}

