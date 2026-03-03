import SwiftUI

struct StoryIntroView: View {
    var onFinished: () -> Void
    
    @State private var sceneIndex = 0
    @State private var transitionOpacity = 0.0
    @State private var animateSpecific = false
    @State private var isSkipped = false
    
    // Typewriter State
    @State private var displayedText = ""
    @State private var displayedSubtext = ""
    
    // Scene Data
    struct StoryScene {
        let image: String
        let color: Color
        let text: String
        let subtext: String
    }
    
    let scenes: [StoryScene] = [
        StoryScene(image: "waveform.path.ecg", color: .red, text: "CRITICAL FAILURE", subtext: "Subject #734 cardiac arrest."),
        StoryScene(image: "brain.head.profile", color: .gray, text: "SYSTEM SHUTDOWN", subtext: "Neural activity 0%."),
        StoryScene(image: "bolt.fill", color: .cyan, text: "ANOMALY DETECTED", subtext: "A single spark remains."),
        StoryScene(image: "network", color: .blue, text: "RECONNECT", subtext: "Wake him up.")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Retro Grid Background (Subtle)
            VStack(spacing: 40) {
                ForEach(0..<20) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                }
            }
            .ignoresSafeArea()
            
            if sceneIndex < scenes.count {
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Animated Visuals
                    ZStack {
                        switch sceneIndex {
                        case 0: // ECG: Draw line
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 100))
                                .foregroundStyle(.red)
                                .shadow(color: .red, radius: 20)
                                .mask(
                                    Rectangle()
                                        .frame(width: 200) // Mask wipe
                                        .offset(x: transitionOpacity > 0 ? 0 : -200)
                                )
                                .animation(.easeOut(duration: 2.0), value: transitionOpacity)
                            
                        case 1: // Brain: Pulse
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 100))
                                .foregroundStyle(.gray)
                                .opacity(animateSpecific ? 1.0 : 0.3)
                                .scaleEffect(animateSpecific ? 1.05 : 0.95)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateSpecific)
                                .onAppear { animateSpecific = true }
                            
                        case 2: // Spark: Jitter
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(.cyan)
                                .shadow(color: .cyan, radius: 30)
                                .offset(x: animateSpecific ? -5 : 5, y: animateSpecific ? -5 : 5)
                                .animation(.linear(duration: 0.1).repeatForever(autoreverses: true), value: animateSpecific)
                                .onAppear { animateSpecific = true }
                            
                        case 3: // Network: Rotate
                            Image(systemName: "network")
                                .font(.system(size: 100))
                                .foregroundStyle(.blue)
                                .rotationEffect(.degrees(animateSpecific ? 360 : 0))
                                .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: animateSpecific)
                                .onAppear { animateSpecific = true }
                            
                        default:
                            EmptyView()
                        }
                    }
                    .opacity(transitionOpacity) // Fade visuals in/out
                    
                    VStack(spacing: 16) {
                        Text(displayedText)
                            .font(.system(size: 32, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(height: 40) // Fixed height
                        
                        Text(displayedSubtext)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .frame(height: 30)
                    }
                    
                    Spacer()
                    
                    // Progress Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<scenes.count, id: \.self) { index in
                            Circle()
                                .fill(index == sceneIndex ? Color.white : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 50)
                }
                .transition(.identity)
            }
        }
        .onAppear {
            animateSequence()
        }
        .onTapGesture {
            completeCurrentScene()
        }
    }
    
    func animateSequence() {
        displayedText = ""
        displayedSubtext = ""
        withAnimation(.easeIn(duration: 0.5)) { transitionOpacity = 1.0 }
        
        typeText(scenes[sceneIndex].text, isTitle: true) {
            typeText(scenes[sceneIndex].subtext, isTitle: false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if isSkipped { return }
                    nextScene()
                }
            }
        }
    }
    
    // Helper for struct state update
    func typeText(_ fullText: String, isTitle: Bool, completion: @escaping () -> Void) {
        var charIndex = 0
        let chars = Array(fullText)
        
        AudioHapticManager.shared.playSound(named: "dragon-studio-keyboard-typing-sound-effect-335503")
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            // Check if we moved on (safety)
            if transitionOpacity == 0 {
                AudioHapticManager.shared.stopSound(named: "dragon-studio-keyboard-typing-sound-effect-335503")
                timer.invalidate()
                return
            }
            
            if charIndex < chars.count {
                if isTitle {
                    displayedText.append(chars[charIndex])
                } else {
                    displayedSubtext.append(chars[charIndex])
                }
                charIndex += 1
            } else {
                AudioHapticManager.shared.stopSound(named: "dragon-studio-keyboard-typing-sound-effect-335503")
                timer.invalidate()
                completion()
            }
        }
    }
    
    func completeCurrentScene() {
        isSkipped = true
        AudioHapticManager.shared.stopSound(named: "dragon-studio-keyboard-typing-sound-effect-335503")
        onFinished()
    }
    
    func nextScene() {
        guard sceneIndex < scenes.count else { return }
        
        withAnimation(.easeOut(duration: 0.3)) {
            transitionOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateSpecific = false
            sceneIndex += 1
            if sceneIndex >= scenes.count {
                onFinished()
            } else {
                animateSequence()
            }
        }
    }
}
