import SwiftUI

struct CinematicIntroView: View {
    var onFinished: () -> Void
    
    // Narrative State
    enum IntroPhase {
        case prologue
        case escape
    }
    
    @State private var phase: IntroPhase = .prologue
    
    // --- Prologue State ---
    @State private var terminalText: String = ""
    @State private var cursorVisible: Bool = true
    @State private var isCancelled: Bool = false
    
    // --- Escape State ---
    // The Spark
    @State private var sparkY: CGFloat = 0 // Vertical position (0 is center)
    @State private var sparkScale: CGFloat = 1.0
    @State private var sparkBlur: CGFloat = 0.0
    
    // Environment
    @State private var tunnelOffset: CGFloat = 0.0
    @State private var obstacles: [ObstacleData] = []
    
    // FX
    @State private var glitchOffset: CGFloat = 0.0
    @State private var isGlitching = false
    @State private var flashOpacity: Double = 0.0
    
    // Configuration
    let terminalGreen = Color(red: 0.1, green: 1.0, blue: 0.4)
    let alertRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    let sparkBlue = Color(red: 0.2, green: 0.8, blue: 1.0)
    
    struct ObstacleData: Identifiable {
        let id = UUID()
        var x: CGFloat // Normalized 0.0 to 1.0+
        var type: Int // 0: Top, 1: Bottom, 2: Middle
        var width: CGFloat
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // MARK: - Phase 1: Prologue
                if phase == .prologue {
                    VStack {
                        Spacer()
                        HStack {
                            Text(terminalText)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(terminalGreen)
                                .multilineTextAlignment(.leading)
                            
                            if cursorVisible {
                                Rectangle()
                                    .fill(terminalGreen)
                                    .frame(width: 10, height: 20)
                            }
                            Spacer()
                        }
                        .padding()
                        Spacer()
                    }
                    .transition(.opacity)
                }
                
                // MARK: - Phase 2: The Escape (Spark Action)
                if phase == .escape {
                    ZStack {
                        // 1. Moving Tunnel / Circuit Lines
                        ForEach(0..<10) { i in
                            Path { path in
                                let y = CGFloat(i) * (geo.size.height / 10)
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                            .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                            .offset(x: (tunnelOffset * CGFloat(i + 1)).truncatingRemainder(dividingBy: 100))
                        }
                        
                        // 2. Obstacles (Red Firewalls)
                        ForEach(obstacles) { obstacle in
                            Rectangle()
                                .fill(alertRed.opacity(0.8))
                                .frame(width: obstacle.width, height: 100)
                                .position(
                                    x: obstacle.x * geo.size.width,
                                    y: getYForObstacle(type: obstacle.type, height: geo.size.height)
                                )
                                .shadow(color: alertRed, radius: 10)
                        }
                        
                        // 3. The Spark (Player)
                        Circle()
                            .fill(sparkBlue)
                            .frame(width: 30, height: 30)
                            .shadow(color: sparkBlue, radius: 15)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 2)
                            )
                            .scaleEffect(sparkScale)
                            .blur(radius: sparkBlur)
                            .position(x: geo.size.width * 0.2, y: (geo.size.height / 2) + sparkY)
                        
                        // 4. Speed Lines (Motion Blur Context)
                        if sparkScale > 1.0 { // Boosting
                            ForEach(0..<5) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 100, height: 2)
                                    .position(
                                        x: CGFloat.random(in: 0...geo.size.width),
                                        y: CGFloat.random(in: 0...geo.size.height)
                                    )
                            }
                        }
                    }
                    .transition(.opacity)
                }
                
                // Flash Overlay for transitions
                Color.white
                    .ignoresSafeArea()
                    .opacity(flashOpacity)
                
                // Skip Button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            isCancelled = true
                            AudioHapticManager.shared.stopSound(named: "dragon-studio-keyboard-typing-sound-effect-335503")
                            AudioHapticManager.shared.playBackgroundMusic(named: "neural_pulse", withExtension: "mp3")
                            onFinished()
                        }) {
                            Text("SKIP >>")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
            .offset(x: glitchOffset, y: glitchOffset) // Shake
            .onAppear {
                AudioHapticManager.shared.pauseBackgroundMusic()
                runPrologue()
            }
        }
    }
    
    // --- Helpers ---
    
    func getYForObstacle(type: Int, height: CGFloat) -> CGFloat {
        switch type {
        case 0: return height * 0.2 // Top
        case 1: return height * 0.8 // Bottom
        default: return height * 0.5 // Middle
        }
    }
    
    // --- Timelines ---
    
    func runPrologue() {
        // Cursor Blink
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if phase != .prologue { timer.invalidate(); return }
            cursorVisible.toggle()
        }
        
        let messages = [
            "PATIENT: SUBJECT #734",
            "STATUS: CRITICAL COMA",
            "VITALS: FADING...",
            "NO PULSE DETECTED.",
            "INITIATING NEURAL REBOOT...",
            "ONE SPARK DETECTED.",
            "WAKE UP."
        ]
        
        var delay = 0.5
        for msg in messages {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if isCancelled { return }
                typeWrite(msg)
            }
            delay += 2.0 // Time to read
        }
        
        // Transition to Action
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 1.0) {
            if isCancelled { return }
            withAnimation(.linear(duration: 0.2)) {
                terminalText = ""
                phase = .escape
                flashOpacity = 1.0
            }
            withAnimation(.linear(duration: 0.5).delay(0.2)) {
                flashOpacity = 0.0
            }
            AudioHapticManager.shared.stopSound(named: "dragon-studio-keyboard-typing-sound-effect-335503")
            AudioHapticManager.shared.playBackgroundMusic(named: "neural_pulse", withExtension: "mp3")
            runEscapeSequence()
        }
    }
    
    func typeWrite(_ text: String) {
        terminalText = ""
        let chars = Array(text)
        var charIndex = 0
        
        AudioHapticManager.shared.playSound(named: "dragon-studio-keyboard-typing-sound-effect-335503")
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if phase != .prologue {
                AudioHapticManager.shared.stopSound(named: "dragon-studio-keyboard-typing-sound-effect-335503")
                timer.invalidate()
                return
            }
            
            if charIndex < chars.count {
                terminalText.append(chars[charIndex])
                // Haptic tick
                if charIndex % 2 == 0 {
                    AudioHapticManager.shared.playUITap(style: .light)
                }
                charIndex += 1
            } else {
                AudioHapticManager.shared.stopSound(named: "dragon-studio-keyboard-typing-sound-effect-335503")
                timer.invalidate()
            }
        }
    }
    
    func runEscapeSequence() {
        // Start scrolling
        withAnimation(.linear(duration: 8.0)) {
            tunnelOffset = -2000
        }
        
        // Generate Obstacles
        for i in 0..<5 {
            obstacles.append(ObstacleData(x: 1.5 + CGFloat(i) * 0.8, type: Int.random(in: 0...2), width: 40))
        }
        
        // Animate Obstacles moving left
        let duration = 6.0
        withAnimation(.linear(duration: duration)) {
            for i in 0..<obstacles.count {
                obstacles[i].x -= 4.0 // Move way left
            }
        }
        
        // Scripted Spark Movements (Dodging)
        scheduleDodge(at: 1.0, to: -100) // Up
        scheduleDodge(at: 2.5, to: 100)  // Down
        scheduleDodge(at: 4.0, to: 0)    // Center
        
        // Glitch Effects during "close calls"
        scheduleGlitch(at: 1.5)
        scheduleGlitch(at: 3.0)
        
        // Final Boost
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeIn(duration: 1.0)) {
                sparkScale = 5.0
                sparkBlur = 10.0
                flashOpacity = 1.0
            }
        }
        
        // Finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            onFinished()
        }
    }
    
    func scheduleDodge(at delay: Double, to y: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                sparkY = y
            }
        }
    }
    
    func scheduleGlitch(at delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isGlitching = true
            // Quick random shakes
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    glitchOffset = CGFloat.random(in: -5...5)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isGlitching = false
                glitchOffset = 0
            }
        }
    }
}
