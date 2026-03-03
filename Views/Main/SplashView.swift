import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void
    
    @State private var terminalText = ""
    @State private var showLogo = false
    @State private var pulse = false
    @State private var opacities: [Double] = [0, 0, 0] // For cinematic text reveal
    
    let bootSequence = [
        "INITIALIZING NEURAL LINK...",
        "ESTABLISHING CONNECTION...",
        "SYNCING MEMORY FRAGMENTS...",
        "SYSTEM ONLINE."
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                if showLogo {
                    ZStack {
                        // Background Ambience
                        RadialGradient(
                            colors: [Color.purple.opacity(0.2), Color.black],
                            center: .center,
                            startRadius: 20,
                            endRadius: 400
                        )
                        .ignoresSafeArea()
                        .transition(.opacity)
                        
                        VStack(spacing: 30) {
                            // Logo Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.cyan.opacity(0.2), .purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)
                                
                                Image(systemName: "bolt.heart.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.cyan, .white, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .cyan.opacity(0.5), radius: 15)
                                    .scaleEffect(pulse ? 1.05 : 1.0)
                            }
                            .opacity(opacities[0])
                            .offset(y: opacities[0] == 1 ? 0 : 20)
                            
                            // Title
                            VStack(spacing: 8) {
                                Text("THE LAST")
                                    .font(.system(size: 24, weight: .light, design: .rounded))
                                    .tracking(8)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .opacity(opacities[1])
                                    .offset(y: opacities[1] == 1 ? 0 : 10)
                                
                                Text("SPARK")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .tracking(4)
                                    .foregroundStyle(.white)
                                    .overlay(
                                        LinearGradient(
                                            colors: [.cyan, .white, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .mask(
                                            Text("SPARK")
                                                .font(.system(size: 48, weight: .black, design: .rounded))
                                                .tracking(4)
                                        )
                                    )
                                    .shadow(color: .purple.opacity(0.5), radius: 20)
                                    .opacity(opacities[2])
                                    .scaleEffect(opacities[2] == 1 ? 1.0 : 1.1)
                            }
                        }
                    }
                    .onAppear {
                        startCinematicReveal()
                    }
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(terminalText)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 40)
                    }
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            runBootSequence()
        }
    }
    
    func runBootSequence() {
        var delay = 0.0
        
        for line in bootSequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                AudioHapticManager.shared.playSound(named: "typewriter")
                terminalText += "> \(line)\n"
            }
            delay += 0.5 // Slightly faster
        }
        
        // Transition to Logo
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                showLogo = true
            }
        }
    }
    
    func startCinematicReveal() {
        withAnimation(.easeOut(duration: 0.8)) {
            opacities[0] = 1.0
        }
        
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulse = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.8)) {
                opacities[1] = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                opacities[2] = 1.0
            }
            AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
            AudioHapticManager.shared.playUITap(style: .heavy)
            
            AudioHapticManager.shared.playBackgroundMusic(named: "neural_pulse", withExtension: "mp3")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            onFinished()
        }
    }
}
