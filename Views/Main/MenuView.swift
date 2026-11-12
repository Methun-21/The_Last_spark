import SwiftUI

public struct MenuView: View {
    // Closure-based navigation to match ContentView
    public var onModeSelected: (GameMode) -> Void
    @ObservedObject var gameViewModel: GameViewModel
    @ObservedObject var storeManager = StoreManager.shared
    
    @State private var showStore = false
    @State private var showProfile = false
    @State private var selectedStoreTab: StoreView.StoreTab = .skins
    @State private var isVoidPulsing = false
    
    // Heart Rate Animation
    @State private var currentBPM = 72
    @State private var isHeartPulsing = false
    
    public init(viewModel: GameViewModel, onModeSelected: @escaping (GameMode) -> Void) {
        self.gameViewModel = viewModel
        self.onModeSelected = onModeSelected
    }
    
    // Coma Patient / Saga Map Interface
    public var body: some View {
        ZStack {
            // 1. Background (Saga View handles its own cosmic background if needed, but we used organic black there)
            // Let's keep AtmosphericBackground as a base layer for depth?
            AtmosphericBackground()
            
            // Vignette for focus
            RadialGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            // 2. Main Content (Saga Map)
            SagaMapView(gameViewModel: gameViewModel) { level in
                playHaptic()
                gameViewModel.selectedLevel = level
                onModeSelected(.story)
            }
            .opacity(showContent ? 1 : 0)
            
            // 3. HUD (Overlay)
            VStack {
                // Top Bar: Modern Status Bar
                HStack(spacing: 12) {
                    // Heart Rate
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.system(size: 14))
                            .scaleEffect(isHeartPulsing ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isHeartPulsing)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(currentBPM)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText(value: Double(currentBPM)))
                            
                            if showStatus {
                                Text(patientStatus)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.orange)
                                    .transition(.opacity)
                            } else {
                                Text("BPM")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .transition(.opacity)
                            }
                        }
                    }
                    .onAppear {
                        isHeartPulsing = true
                        startHeartRateSimulation()
                    }
                    .onTapGesture {
                        playHaptic()
                        withAnimation {
                            showStatus = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation {
                                showStatus = false
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [.red.opacity(0.5), .pink.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    
                    Spacer()
                    
                    // Energy
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(storeManager.balance)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("ENERGY")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                     .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.5), .orange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Bottom Bar: GlassDock
                HStack(spacing: 0) {
                    // VOID (Endless)
                    Button(action: {
                        playHaptic()
                        onModeSelected(.endless)
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "infinity")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.cyan)
                                .shadow(color: .cyan.opacity(0.5), radius: 8)
                                .scaleEffect(isVoidPulsing ? 1.1 : 1.0)
                            Text("Void")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                isVoidPulsing = true
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 1, height: 30)
                    
                    // SHOP
                    Button(action: {
                        playHaptic()
                        selectedStoreTab = .skins
                        showStore = true
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("Shop")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 1, height: 30)
                    
                    // PROFILE
                    Button(action: {
                        playHaptic()
                        showProfile = true
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: .white.opacity(0.3), radius: 8)
                            Text("Profile")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.vertical, 16)
                .background(.ultraThinMaterial) // Stronger material
                .background(Color.black.opacity(0.2)) // Added depth
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05), .white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showStore) {
            StoreView(onBack: { showStore = false }, initialTab: selectedStoreTab)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(gameViewModel: gameViewModel, isPresented: $showProfile)
        }
    }
    
    @State private var showContent = false
    
    @State private var showStatus = false
    
    private func playHaptic() {
        AudioHapticManager.shared.playUITap(style: .medium)
        AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
    }
    
    // Status text based on progression
    private var patientStatus: String {
        switch gameViewModel.unlockedLevels {
        case 1...10: return "DEEP SLEEP"
        case 11...20: return "REM CYCLE"
        case 21...29: return "LUCID DREAMING"
        case 30...: return "WAKING UP"
        default: return "STABLE"
        }
    }
    
    private func startHeartRateSimulation() {
        // Dynamic Base BPM based on level progression (Coma -> Waking)
        // Level 1: ~60 BPM
        // Level 30: ~105 BPM
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                let baseBPM = 60 + (gameViewModel.unlockedLevels * 3 / 2)
                
                // Random walk logic
                let change = Int.random(in: -3...3)
                let newBPM = currentBPM + change
                
                // Clamp around the dynamic base
                let minBPM = baseBPM - 5
                let maxBPM = baseBPM + 5
                
                if newBPM >= minBPM && newBPM <= maxBPM {
                    currentBPM = newBPM
                } else {
                    currentBPM = baseBPM // Return to baseline if out of bounds
                }
            }
        }
    }
}
