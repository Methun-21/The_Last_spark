import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var gameState: GameState = .splash
    @State private var flashOpacity: Double = 0.0
    @State private var showStoryIntro = false
    @State private var showEducationalIntro = false
    @AppStorage("hasSeenEducationalIntro") private var hasSeenEducationalIntro = false
    
    enum GameState {
        case splash
        case menu
        case levelSelect
        case playing
        case ending
    }
    
    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Priority 0: Splash Screen
            if gameState == .splash {
                SplashView {
                    withAnimation {
                        // Show educational intro on first launch
                        if !hasSeenEducationalIntro {
                            gameState = .menu // CRITICAL: Change state first
                            showEducationalIntro = true
                        } else {
                            gameState = .menu
                        }
                    }
                }
                .transition(.opacity)
                .zIndex(20)
            }
            
            // Priority 0.5: Educational Intro (First Launch)
            if showEducationalIntro && gameState == .menu {
                EducationalIntroView {
                    withAnimation {
                        hasSeenEducationalIntro = true
                        showEducationalIntro = false
                    }
                }
                .transition(.opacity)
                .zIndex(15)
            }
            
            
            // Priority 1: Story Intro
            if showStoryIntro && gameState == .menu {
                CinematicIntroView {
                    withAnimation {
                        showStoryIntro = false
                        startGame()
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
            
            // Priority 2: Menu
            if gameState == .menu && !showEducationalIntro && !showStoryIntro {
                MenuView(viewModel: viewModel, onModeSelected: { mode in
                    viewModel.gameMode = mode
                    
                    if mode == .story {
                        if viewModel.selectedLevel == 1 {
                            withAnimation {
                                showStoryIntro = true
                            }
                        } else {
                            triggerFlashTransition()
                        }
                    } else {
                        triggerFlashTransition()
                    }
                })
                .transition(.opacity)
            }
            
            // Priority 3: Game
            if gameState == .playing {
                EndlessGameScene(viewModel: viewModel, onBack: {
                    withAnimation {
                        gameState = .menu
                    }
                })
                .transition(.opacity)
            }
            
            // Priority 4: Ending
            if gameState == .ending {
                CinematicOutroView {
                    withAnimation {
                        viewModel.gameWon = false
                        viewModel.score = 0
                        gameState = .menu
                        AudioHapticManager.shared.playBackgroundMusic(named: "neural_pulse", withExtension: "mp3")
                    }
                }
                .transition(.opacity)
                .zIndex(30)
            }
            
            // Flash Overlay
            Color.white
                .ignoresSafeArea()
                .opacity(flashOpacity)
                .allowsHitTesting(false)
        }
        .onAppear {
            viewModel.prepareHaptics()
        }
        .onChange(of: viewModel.gameWon) { won in
            if won {
                withAnimation {
                    gameState = .ending
                }
            }
        }
    }
    
    func triggerFlashTransition() {
        withAnimation(.easeIn(duration: 0.1)) {
            flashOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            startGame()
            withAnimation(.easeOut(duration: 0.5)) {
                flashOpacity = 0.0
            }
        }
    }
    
    func startGame() {
        gameState = .playing
        viewModel.startGame(level: viewModel.selectedLevel, size: UIScreen.main.bounds.size)
    }
}
