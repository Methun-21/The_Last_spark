import SwiftUI
import CoreHaptics

struct CinematicOutroView: View {
    var onFinished: () -> Void
    
    @State private var phase = 0
    @State private var flashOpacity: Double = 0.0
    @State private var textOpacity1: Double = 0.0
    @State private var textOpacity2: Double = 0.0
    @State private var textOpacity3: Double = 0.0
    
    // Heartbeat/EKG
    @State private var ekgProgress: CGFloat = 0.0
    @State private var showReturnButton = false
    @State private var isFlatline = true
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Phase 1 & 2: EKG and Text
            VStack(spacing: 40) {
                // EKG Graphic
                ZStack {
                    if isFlatline {
                        // Flatline
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 50))
                            path.addLine(to: CGPoint(x: 300, y: 50))
                        }
                        .trim(from: 0, to: ekgProgress)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 300, height: 100)
                    } else {
                        // Healthy Heartbeat
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 50))
                            path.addLine(to: CGPoint(x: 100, y: 50))
                            path.addLine(to: CGPoint(x: 115, y: 20))
                            path.addLine(to: CGPoint(x: 135, y: 90))
                            path.addLine(to: CGPoint(x: 155, y: 10))
                            path.addLine(to: CGPoint(x: 175, y: 70))
                            path.addLine(to: CGPoint(x: 190, y: 50))
                            path.addLine(to: CGPoint(x: 300, y: 50))
                        }
                        .trim(from: 0, to: ekgProgress)
                        .stroke(
                            LinearGradient(colors: [.cyan, .green], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 300, height: 100)
                        .shadow(color: .cyan.opacity(0.8), radius: 10)
                        // Pulse the healthy beat
                        .scaleEffect(pulse ? 1.05 : 1.0)
                    }
                }
                .opacity(textOpacity1) // Show at the same time as the first text
                
                VStack(spacing: 16) {
                    Text("SUBJECT #734")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.gray)
                        .opacity(textOpacity1)
                    
                    Text("NEURAL LINK RESTORED")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .white, .green], startPoint: .leading, endPoint: .trailing)
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                        .opacity(textOpacity2)
                }
                
                Text("WAKING UP...")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(textOpacity3)
                
                if showReturnButton {
                    Button(action: {
                        AudioHapticManager.shared.playUITap(style: .heavy)
                        onFinished()
                    }) {
                        Text("RETURN TO REALITY")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .white.opacity(0.5), radius: 10)
                    }
                    .padding(.top, 40)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            
            // Flash Overlay
            Color.white
                .ignoresSafeArea()
                .opacity(flashOpacity)
                .allowsHitTesting(false)
        }
        .onAppear {
            runCinematicSequence()
        }
    }
    
    func runCinematicSequence() {
        // Pause all other game music
        AudioHapticManager.shared.pauseBackgroundMusic()
        
        // Initial White Flash (Wake Up Shock)
        withAnimation(.easeIn(duration: 0.1)) {
            flashOpacity = 1.0
        }
        
        AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
        AudioHapticManager.shared.playEnhancedCollision()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 3.0)) {
                flashOpacity = 0.0
            }
        }
        
        // 1. Show Flatline / Subject
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 1.0)) {
                textOpacity1 = 1.0
            }
            // Draw Flatline
            withAnimation(.linear(duration: 2.0)) {
                ekgProgress = 1.0
            }
            // Continuous beep sound
            AudioHapticManager.shared.playSound(named: "GameOver")
        }
        
        // 2. The Revive/Spark happens (Heartbeat changes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // Flash again quickly
            withAnimation(.easeIn(duration: 0.1)) {
                flashOpacity = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 1.0)) {
                    flashOpacity = 0.0
                }
            }
            
            isFlatline = false // Switch path
            ekgProgress = 0.0 // Reset drawing
            
            AudioHapticManager.shared.playSound(named: "PowerUp")
            AudioHapticManager.shared.playEnhancedPowerUp()
            
            // Redraw healthy beat
            withAnimation(.easeInOut(duration: 1.5)) {
                ekgProgress = 1.0
                textOpacity2 = 1.0 // NEURAL LINK RESTORED
            }
            
            // Start pulsing
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        
        // 3. Waking Up Text
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
            withAnimation(.easeIn(duration: 1.0)) {
                textOpacity3 = 1.0
            }
            AudioHapticManager.shared.playUITap(style: .light)
        }
        
        // 4. Show Return Button
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showReturnButton = true
            }
            AudioHapticManager.shared.playUITap(style: .medium)
            
            // Play victorious music back
            AudioHapticManager.shared.playBackgroundMusic(named: "neural_pulse", withExtension: "mp3")
        }
    }
}
