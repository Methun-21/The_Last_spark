import SwiftUI

struct GaugeView: View {
    var score: Int
    
    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0.0, to: 0.5)
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(180))
            
            // Progress arc (Simulated based on score cap of 5000 for visual)
            Circle()
                .trim(from: 0.0, to: min(CGFloat(score) / 5000.0 * 0.5, 0.5))
                .stroke(
                    LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(180))
                .shadow(color: .cyan.opacity(0.6), radius: 8)
            
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan.opacity(0.5), radius: 5)
                
                Text("HIGHSCORE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.gray)
            }
            .offset(y: -10)
        }
    }
}
