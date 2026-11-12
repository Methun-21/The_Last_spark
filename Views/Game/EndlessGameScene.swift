import SwiftUI

struct EndlessGameScene: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var storeManager = StoreManager.shared
    var onBack: () -> Void
    @State private var dragStartPlayerX: CGFloat? = nil
    @State private var isCriticalPulsing = false
    
    var body: some View {
        let skinColor = storeManager.getColor(for: storeManager.selectedSkinID)
        
        GeometryReader { geo in
            ZStack {
                // 1. Cosmic Background
                AtmosphericBackground()
                    .ignoresSafeArea()
                
                // 2. Game World
                obstaclesView(geo: geo)
                powerUpView(geo: geo)
                playerView(skinColor: skinColor, geo: geo) // Player on top
                
                // 3. UI Layer
                scoreView(geo: geo)
                
                // 4. Overlays
                revivePopupOverlay(geo: geo)
                gameEndedOverlay(geo: geo)
                messageOverlays(geo: geo)
                
                // 5. Collision Effect (Spark animation)
                if viewModel.showCollisionEffect {
                    CollisionSparkEffect()
                        .position(viewModel.collisionPosition)
                }
                
                // Debug Overlay (Optional, checking debugMode)
                if viewModel.debugMode {
                    debugHitboxOverlay(geo: geo)
                }
            }
            .overlay(dragGestureOverlay)
            .overlay(pauseButtonOverlay(geo: geo))
            .onAppear {
                viewModel.prepareHaptics()
                viewModel.updateGameSize(size: geo.size)
                
                if !viewModel.alive && !viewModel.showRevivePopup {
                   viewModel.startGame(level: viewModel.selectedLevel, size: geo.size, newGame: true)
                } else if viewModel.showRevivePopup {
                   // Waiting for user input
                } else {
                   if viewModel.obstacleRows.isEmpty {
                       viewModel.startGame(level: viewModel.selectedLevel, size: geo.size, newGame: true)
                   }
                }
            }
            .onChange(of: geo.size) { newSize in
                viewModel.updateGameSize(size: newSize)
            }
            .onDisappear {
                viewModel.stopGame()
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    func playerView(skinColor: Color, geo: GeometryProxy) -> some View {
        ZStack {
            PlayerView(skinColor: skinColor)
                .frame(width: viewModel.playerRadius * 2.5, height: viewModel.playerRadius * 2.5)
            
            // Shield Effect - Enhanced visibility
            if viewModel.shieldActive {
                ShieldEffect()
                    .frame(width: viewModel.playerRadius * 3.5, height: viewModel.playerRadius * 3.5)
                    .accessibilityLabel("Shield active")
            }
        }
        .position(x: geo.size.width/2 + viewModel.playerX, y: geo.size.height - 60)
        .opacity(viewModel.isInvincible ? 0.4 : 1.0) // Blinking/Ghost effect
        .animation(viewModel.isInvincible ? Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true) : .default, value: viewModel.isInvincible)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.shieldActive ? "Player with shield protection" : "Player")
    }
    
    @ViewBuilder
    func obstaclesView(geo: GeometryProxy) -> some View {
        ForEach(viewModel.obstacleRows.flatMap { $0.obstacles }) { obs in
            ObstacleView(width: obs.width, height: 18)
                .position(x: geo.size.width/2 + obs.x, y: obs.y)
        }
    }
    
    @ViewBuilder
    func powerUpView(geo: GeometryProxy) -> some View {
        if let pu = viewModel.powerUp {
            ZStack {
                switch pu.type {
                case .revive:
                    // Heart Icon for Revive
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.pink.opacity(0.8), Color.red],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 30, height: 30)
                            .blur(radius: 3)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .shadow(color: .pink, radius: 5)
                    }
                    .scaleEffect(viewModel.alive ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.alive)
                    
                case .scoreMultiplier:
                    // Stylish 2x Multiplier Token
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [Color.purple.opacity(0.9), Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: .purple.opacity(0.8), radius: 6)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: 32, height: 32)
                        
                        Text("2x")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                    }
                    
                default:
                    // Stylish Shield Token
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [Color.yellow.opacity(0.9), Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: .orange.opacity(0.8), radius: 6)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "shield.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                    }
                }
            }
            .position(x: geo.size.width/2 + pu.x, y: pu.y)
            .animation(.easeInOut(duration: 0.3), value: pu.y)
        }
    }
    
    @ViewBuilder
    func scoreView(geo: GeometryProxy) -> some View {
        if viewModel.alive || viewModel.showRevivePopup {
            VStack(spacing: 8) {
                // Score Display
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityHidden(true)
                    
                    if viewModel.gameMode == .story {
                        // Show Progress: Current / Target
                        let target = viewModel.selectedLevel * 1000
                        Text("\(viewModel.score) / \(target)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: Double(viewModel.score)))
                    } else {
                        // Standard Score
                        Text("\(viewModel.score)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: Double(viewModel.score)))
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Score: \(viewModel.score) points")
                .padding(.top, 60)
                .shadow(color: .black.opacity(0.5), radius: 2)

                if viewModel.gameMode == .story {
                    Text("CHAPTER \(viewModel.selectedLevel)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .accessibilityLabel("Chapter \(viewModel.selectedLevel)")
                } else {
                    Text("BEST: \(viewModel.highScore)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .accessibilityLabel("Best score: \(viewModel.highScore) points")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: geo.size.width/2, y: 50)
        }
    }
    
    
    @ViewBuilder
    func revivePopupOverlay(geo: GeometryProxy) -> some View {
        if viewModel.showRevivePopup {
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Heart Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.pink.opacity(0.8), Color.red],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 8)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .shadow(color: .pink, radius: 15)
                    }
                    .scaleEffect(1.1)
                    .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.showRevivePopup)
                    
                    Text("CONTINUE?")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Use 1 Revive to continue where you left off")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // Revive Count
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        Text("\(StoreManager.shared.reviveCount) Revives Available")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    
                    // Buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.skipRevive()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 40))
                                Text("SKIP")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 120)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.05)))
                        }
                        .accessibilityLabel("Skip revive and end game")
                        .accessibilityHint("Double tap to end the game")
                        
                        Button(action: {
                            viewModel.useRevive()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 50))
                                Text("CONTINUE")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(width: 120)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.1)))
                            )
                        }
                        .accessibilityLabel("Use revive to continue playing")
                        .accessibilityHint("Double tap to use one revive and continue the game")
                    }
                    .padding(.top, 10)
                }
                .padding(40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(radius: 30)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    func gameEndedOverlay(geo: GeometryProxy) -> some View {
        // Special Game Won / Subject Waked Up Overlay
        if viewModel.gameWon {
             ZStack {
                 Color.white.ignoresSafeArea()
                     .transition(.opacity)
                 
                 VStack(spacing: 30) {
                     Text("SUBJECT WAKED UP")
                         .font(.system(size: 32, weight: .black, design: .rounded))
                         .foregroundStyle(.black)
                         .shadow(color: .black.opacity(0.1), radius: 10)
                         .scaleEffect(isCriticalPulsing ? 1.05 : 1.0)
                         .onAppear {
                             withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                 isCriticalPulsing = true
                             }
                         }
                     
                     Text("Synapses Restored: \(viewModel.score)")
                         .font(.title3)
                         .foregroundStyle(.gray)
                     
                     Button(action: {
                         viewModel.stopGame()
                         onBack()
                     }) {
                         Text("RETURN TO REALITY")
                             .font(.headline)
                             .foregroundStyle(.white)
                             .padding()
                             .padding(.horizontal, 20)
                             .background(Color.blue)
                             .clipShape(Capsule())
                             .shadow(radius: 5)
                     }
                 }
             }
             .zIndex(100)
        } else if !viewModel.alive && !viewModel.showRevivePopup {
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                
                BentoCard {
                    VStack(spacing: 24) {
                        Text("SIGNAL LOST")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(.red)
                        
                        VStack(spacing: 4) {
                            Text("\(viewModel.score)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text("SYNAPSES COLLECTED")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        
                        Divider().background(.white.opacity(0.2))
                        
                        HStack(spacing: 40) {
                            Button(action: {
                                viewModel.stopGame()
                                onBack()
                            }) {
                                VStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title)
                                    Text("EXIT")
                                        .font(.caption)
                                        .bold()
                                }
                                .foregroundStyle(.white.opacity(0.7))
                            }
                            
                            Button(action: {
                                viewModel.restartGame(size: geo.size)
                            }) {
                                VStack {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white)
                                    Text("RETRY")
                                        .font(.caption)
                                        .bold()
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .padding(30)
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    @ViewBuilder
    func messageOverlays(geo: GeometryProxy) -> some View {
        if viewModel.levelComplete {
             ZStack {
                 Color.black.opacity(0.8).ignoresSafeArea()
                 
                 BentoCard {
                     VStack(spacing: 24) {
                         Text("CHAPTER \(viewModel.selectedLevel) COMPLETE")
                             .font(.system(size: 24, weight: .heavy, design: .rounded))
                             .foregroundStyle(.cyan)
                             .multilineTextAlignment(.center)
                         
                         VStack(spacing: 4) {
                             Text("NEURAL PATHWAY SECURED")
                                 .font(.system(size: 14, weight: .bold, design: .monospaced))
                                 .foregroundStyle(.white.opacity(0.8))
                         }
                         
                         Divider().background(.white.opacity(0.2))
                         
                         Button(action: {
                             withAnimation {
                                 viewModel.startNextLevel(size: geo.size)
                             }
                         }) {
                             VStack {
                                 Image(systemName: "arrow.right.circle.fill")
                                     .font(.largeTitle)
                                     .foregroundStyle(.cyan)
                                 Text("CONTINUE")
                                     .font(.caption)
                                     .bold()
                                     .foregroundStyle(.cyan)
                             }
                             .padding()
                             .background(RoundedRectangle(cornerRadius: 16).fill(.cyan.opacity(0.1)))
                         }
                     }
                     .padding(30)
                 }
                 .padding(.horizontal, 40)
             }
         }
         
         if viewModel.isPaused && !viewModel.showRevivePopup {
             ZStack {
                 Color.black.opacity(0.4).ignoresSafeArea()
                 BentoCard {
                     VStack(spacing: 20) {
                         Text("PAUSED")
                             .font(.headline)
                             .foregroundStyle(.white.opacity(0.8))
                         
                         HStack(spacing: 40) {
                             Button(action: { viewModel.togglePause() }) {
                                 Image(systemName: "play.circle.fill")
                                     .font(.system(size: 50))
                                     .foregroundStyle(.white)
                             }
                             .accessibilityLabel("Resume game")
                             .accessibilityHint("Double tap to continue playing")
                             
                             Button(action: { 
                                 viewModel.stopGame()
                                 onBack() 
                             }) {
                                 Image(systemName: "house.circle.fill")
                                     .font(.system(size: 50))
                                     .foregroundStyle(.white.opacity(0.5))
                             }
                             .accessibilityLabel("Return to menu")
                             .accessibilityHint("Double tap to exit game and return to main menu")
                         }
                     }
                     .padding(30)
                 }
             }
         }
    }
    
    // Drag Gesture Overlay Component
    var dragGestureOverlay: some View {
        Group {
            if viewModel.alive && !viewModel.levelComplete && !viewModel.gameWon && !viewModel.isPaused && !viewModel.showRevivePopup {
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if dragStartPlayerX == nil {
                                        dragStartPlayerX = viewModel.playerX
                                    }
                                    guard let startX = dragStartPlayerX else { return }
                                    let newX = startX + value.translation.width
                                    
                                    // Use visual radius (28px) for movement bounds
                                    // This allows the ball to reach the edge where collision will trigger
                                    let visualRadius: CGFloat = 28
                                    let halfWidth = viewModel.gameWidth / 2 - visualRadius
                                    
                                    // Allow movement to edge - collision detection will handle death
                                    viewModel.playerX = min(max(newX, -halfWidth), halfWidth)
                                }
                                .onEnded { _ in
                                    dragStartPlayerX = nil
                                }
                        )
                }
            }
        }
    }
    
    func pauseButtonOverlay(geo: GeometryProxy) -> some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    viewModel.isPaused.toggle()
                    AudioHapticManager.shared.playUITap(style: .light)
                }) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .accessibilityLabel(viewModel.isPaused ? "Resume game" : "Pause game")
                .accessibilityHint(viewModel.isPaused ? "Double tap to continue playing" : "Double tap to pause the game")
                .padding(.top, 60)
                .padding(.trailing, 20)
            }
            Spacer()
        }
    }
    
    func debugHitboxOverlay(geo: GeometryProxy) -> some View {
        ZStack {
            Circle()
                .stroke(Color.green, lineWidth: 2)
                .frame(width: 12, height: 12)
                .position(x: geo.size.width/2 + viewModel.playerX, y: geo.size.height - 60)
            
            ForEach(viewModel.obstacleRows.flatMap { $0.obstacles }) { obs in
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: obs.width * 0.3, height: 10)
                    .position(x: geo.size.width/2 + obs.x, y: obs.y)
            }
        }
        .allowsHitTesting(false)
    }
}
