import SwiftUI

struct EndlessGameScene: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var storeManager = StoreManager.shared
    var onBack: () -> Void
    @State private var dragStartPlayerX: CGFloat? = nil
    @State private var isCriticalPulsing = false
    @AppStorage("dashTutorialShown") private var dashTutorialShown: Bool = false
    @State private var showDashTip: Bool = false
    @State private var lastTapTime: TimeInterval = 0
    
    var body: some View {
        let skinColor = storeManager.getColor(for: storeManager.selectedSkinID)
        
        GeometryReader { geo in
            ZStack {
                // 1. Cosmic Background
                AtmosphericBackground()
                    .ignoresSafeArea()
                
                // 2. Game World (with Screen Shake)
                ZStack {
                    obstaclesView(geo: geo)
                    powerUpView(geo: geo)
                    
                    // Synaptic Gateway Finish Line (Story Mode)
                    if viewModel.isApproachingGate {
                        SynapseGatewayView(
                            width: viewModel.gameWidth,
                            sectorColor: GameLevelInfo.info(for: viewModel.selectedLevel).sector.themeColor,
                            isPassing: viewModel.isPassingGate
                        )
                        .position(x: geo.size.width / 2, y: viewModel.gateY)
                    }
                    
                    playerView(skinColor: skinColor, geo: geo)
                }
                .offset(x: viewModel.screenShakeOffset)
                
                // 3. UI Layer (Top HUD, Score, Shards)
                scoreView(geo: geo)
                
                // 4. Overlays & Toasts
                if viewModel.showNearMissToast {
                    Text(viewModel.nearMissText)
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.yellow.opacity(0.8), lineWidth: 1.5))
                        .shadow(color: .yellow.opacity(0.6), radius: 8)
                        .position(viewModel.nearMissPosition)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // DASH Tutorial Tip (shows once, 3.5s)
                if showDashTip {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("⚡ SYNAPTIC DASH")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundStyle(.cyan)
                                Text("Double-tap screen or tap\nDASH to phase through barriers!")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cyan.opacity(0.5), lineWidth: 1))
                            .shadow(color: .cyan.opacity(0.3), radius: 8)
                            .padding(.trailing, 94)
                            .padding(.bottom, 32)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .allowsHitTesting(false)
                }
                
                revivePopupOverlay(geo: geo)
                gameEndedOverlay(geo: geo)
                messageOverlays(geo: geo)
                
                // Victory Warp Flash Bloom
                Color.white
                    .ignoresSafeArea()
                    .opacity(viewModel.victoryFlashOpacity)
                    .allowsHitTesting(false)
                
                // 5. Collision Effect (Spark animation)
                if viewModel.showCollisionEffect {
                    CollisionSparkEffect()
                        .position(viewModel.collisionPosition)
                }
                
                // Debug Overlay
                if viewModel.debugMode {
                    debugHitboxOverlay(geo: geo)
                }
            }
            .overlay(dragGestureOverlay)
            .overlay(controlsOverlay(geo: geo))
            .overlay(pauseButtonOverlay(geo: geo))
            .onAppear {
                viewModel.prepareHaptics()
                viewModel.updateGameSize(size: geo.size)
                
                if !viewModel.alive && !viewModel.showRevivePopup {
                   viewModel.startGame(level: viewModel.selectedLevel, size: geo.size, newGame: true)
                } else if !viewModel.showRevivePopup && viewModel.obstacleRows.isEmpty {
                   viewModel.startGame(level: viewModel.selectedLevel, size: geo.size, newGame: true)
                }
                
                // Show dash tutorial tip once per install
                if !dashTutorialShown {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeIn(duration: 0.4)) { showDashTip = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            withAnimation(.easeOut(duration: 0.5)) { showDashTip = false }
                            dashTutorialShown = true
                        }
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
            PlayerView(
                skinColor: skinColor,
                isDashing: viewModel.isDashing,
                isInvincible: viewModel.isInvincible
            )
            .frame(width: viewModel.playerRadius * 2.5, height: viewModel.playerRadius * 2.5)
            
            // Shield Effect
            if viewModel.shieldActive {
                ShieldEffect()
                    .frame(width: viewModel.playerRadius * 3.5, height: viewModel.playerRadius * 3.5)
                    .transition(.identity)
                    .accessibilityLabel("Shield active")
            }
        }
        .position(x: geo.size.width / 2 + viewModel.playerX, y: geo.size.height - 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.shieldActive ? "Player with shield protection" : "Player")
    }
    
    @ViewBuilder
    func obstaclesView(geo: GeometryProxy) -> some View {
        ForEach(viewModel.obstacleRows.flatMap { $0.obstacles }) { obs in
            let splitX: CGFloat = viewModel.splitObstaclesOffset > 0
                ? (obs.x >= 0 ? viewModel.splitObstaclesOffset : -viewModel.splitObstaclesOffset)
                : 0
            ObstacleView(width: obs.width, height: 18, type: obs.type, color: obs.color)
                .position(x: geo.size.width / 2 + obs.x + splitX, y: obs.y)
                .animation(.easeOut(duration: 0.35), value: viewModel.splitObstaclesOffset)
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
                            .frame(width: 32, height: 32)
                            .blur(radius: 3)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .shadow(color: .pink, radius: 5)
                    }
                    .scaleEffect(viewModel.alive ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.alive)
                    
                case .scoreMultiplier:
                    // 2x Multiplier Token
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.purple.opacity(0.9), Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 34, height: 34)
                            .shadow(color: .purple.opacity(0.8), radius: 6)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            .frame(width: 34, height: 34)
                        
                        Text("2x")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                case .energyCell:
                    // Cyan Dash Energy Battery
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [.cyan, .blue], center: .center, startRadius: 4, endRadius: 20))
                            .frame(width: 32, height: 32)
                            .shadow(color: .cyan.opacity(0.8), radius: 8)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                    }
                    
                case .memoryShard:
                    // Golden Narrative Shard
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [.yellow, .orange], center: .center, startRadius: 5, endRadius: 24))
                            .frame(width: 36, height: 36)
                            .shadow(color: .yellow.opacity(0.9), radius: 10)
                        
                        Image(systemName: "sparkle")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(1.1)
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pu.y)
                    
                default:
                    // Shield Token
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.yellow.opacity(0.9), Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                            .shadow(color: .orange.opacity(0.8), radius: 6)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "shield.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .position(x: geo.size.width / 2 + pu.x, y: pu.y)
            .animation(.easeInOut(duration: 0.3), value: pu.y)
        }
    }
    
    @ViewBuilder
    func scoreView(geo: GeometryProxy) -> some View {
        if viewModel.alive || viewModel.showRevivePopup {
            VStack(spacing: 8) {
                // Top Progress & Score Display
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    
                    if viewModel.gameMode == .story {
                        let target = viewModel.selectedLevel * 1000
                        let displayScore = min(viewModel.score, target)
                        Text("\(displayScore) / \(target)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: Double(displayScore)))
                    } else {
                        Text("\(viewModel.score)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: Double(viewModel.score)))
                    }
                    
                    if viewModel.nearMissStreak > 1 {
                        Text("x\(viewModel.nearMissStreak)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 56)
                .shadow(color: .black.opacity(0.5), radius: 2)

                if viewModel.gameMode == .story {
                    let info = GameLevelInfo.info(for: viewModel.selectedLevel)
                    VStack(spacing: 4) {
                        Text("\(info.sector.name) • CH. \(viewModel.selectedLevel)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(info.sector.themeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        
                        // Gateway approach notification
                        if viewModel.isPassingGate {
                            Text("✦ JUMP INITIATED ✦")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(info.sector.themeColor)
                                .clipShape(Capsule())
                                .transition(.scale.combined(with: .opacity))
                        } else if viewModel.isApproachingGate {
                            Text("SYNAPSE GATE IN SIGHT")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(info.sector.themeColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(info.sector.themeColor, lineWidth: 1))
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // 3 Memory Shards Indicators
                        HStack(spacing: 6) {
                            ForEach(1...3, id: \.self) { idx in
                                Image(systemName: idx <= viewModel.levelShardsCollected ? "sparkle" : "sparkle")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(idx <= viewModel.levelShardsCollected ? Color.yellow : Color.white.opacity(0.25))
                            }
                        }
                    }
                } else {
                    Text("BEST: \(viewModel.highScore)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: geo.size.width / 2, y: 55)
        }
    }
    
    // MARK: - TOUGHNESS: Dash Button Overlay
    @ViewBuilder
    func controlsOverlay(geo: GeometryProxy) -> some View {
        if viewModel.alive && !viewModel.isPaused && !viewModel.levelComplete && !viewModel.gameWon {
            let dashCount = storeManager.dashCount
            let canDash = dashCount > 0 && !viewModel.isDashing
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { viewModel.performDash() }) {
                        ZStack {
                            // Background circle
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 68, height: 68)
                            
                            Circle()
                                .stroke(canDash ? Color.cyan.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 2)
                                .frame(width: 68, height: 68)
                            
                            VStack(spacing: 3) {
                                // Bolt icon
                                Image(systemName: viewModel.isDashing ? "bolt.fill" : "bolt.horizontal.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(canDash ? .cyan : .gray)
                                    .symbolEffect(.pulse, isActive: viewModel.isDashing)
                                
                                // Count display — like heart lives
                                HStack(spacing: 2) {
                                    ForEach(0..<min(dashCount, 5), id: \.self) { _ in
                                        Circle()
                                            .fill(Color.cyan)
                                            .frame(width: 6, height: 6)
                                    }
                                    if dashCount > 5 {
                                        Text("+\(dashCount - 5)")
                                            .font(.system(size: 7, weight: .black, design: .monospaced))
                                            .foregroundStyle(.cyan)
                                    }
                                    if dashCount == 0 {
                                        Text("0")
                                            .font(.system(size: 11, weight: .black, design: .monospaced))
                                            .foregroundStyle(.gray)
                                    }
                                }
                                
                                Text("DASH")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundStyle(canDash ? .white.opacity(0.8) : .gray)
                            }
                        }
                        .shadow(color: canDash ? .cyan.opacity(0.4) : .clear, radius: 10)
                        .scaleEffect(viewModel.isDashing ? 1.12 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: viewModel.isDashing)
                    }
                    .disabled(!canDash)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    func revivePopupOverlay(geo: GeometryProxy) -> some View {
        if viewModel.showRevivePopup {
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()
                
                VStack(spacing: 24) {
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
                            .frame(width: 110, height: 110)
                            .blur(radius: 8)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(.white)
                            .shadow(color: .pink, radius: 15)
                    }
                    .scaleEffect(1.1)
                    .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.showRevivePopup)
                    
                    Text("CONTINUE?")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Use 1 Revive to restore vital neural pulse")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        Text("\(StoreManager.shared.reviveCount) Available")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.skipRevive()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 36))
                                Text("GIVE UP")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 110)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.05)))
                        }
                        
                        Button(action: {
                            viewModel.useRevive()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 44))
                                Text("REVIVE")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(width: 110)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.12)))
                            )
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(36)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(radius: 30)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    func gameEndedOverlay(geo: GeometryProxy) -> some View {
        if viewModel.gameWon {
             ZStack {
                 Color.white.ignoresSafeArea()
                     .transition(.opacity)
                 
                 VStack(spacing: 28) {
                     Text("SUBJECT AWAKENED")
                         .font(.system(size: 32, weight: .black, design: .rounded))
                         .foregroundStyle(.black)
                         .scaleEffect(isCriticalPulsing ? 1.05 : 1.0)
                         .onAppear {
                             withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                 isCriticalPulsing = true
                             }
                         }
                     
                     Text("Synapses Restored: \(viewModel.score)")
                         .font(.headline)
                         .foregroundStyle(.gray)
                     
                     Button(action: {
                         viewModel.stopGame()
                         onBack()
                     }) {
                         Text("RETURN TO REALITY")
                             .font(.headline)
                             .foregroundStyle(.white)
                             .padding()
                             .padding(.horizontal, 24)
                             .background(Color.blue)
                             .clipShape(Capsule())
                             .shadow(radius: 5)
                     }
                 }
             }
             .zIndex(100)
        } else if !viewModel.alive && !viewModel.showRevivePopup {
            ZStack {
                Color.black.opacity(0.65).ignoresSafeArea()
                
                BentoCard {
                    VStack(spacing: 22) {
                        Text("SIGNAL LOST")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(.red)
                        
                        VStack(spacing: 4) {
                            Text("\(viewModel.score)")
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text("SYNAPSES COLLECTED")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
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
                    .padding(26)
                }
                .padding(.horizontal, 36)
            }
        }
    }
    
    @ViewBuilder
    func messageOverlays(geo: GeometryProxy) -> some View {
        if viewModel.levelComplete {
             let info = GameLevelInfo.info(for: viewModel.selectedLevel)
             ZStack {
                 Color.black.opacity(0.85).ignoresSafeArea()
                 
                 BentoCard {
                     VStack(spacing: 20) {
                         Text("CHAPTER \(viewModel.selectedLevel) COMPLETE")
                             .font(.system(size: 22, weight: .heavy, design: .rounded))
                             .foregroundStyle(info.sector.themeColor)
                             .multilineTextAlignment(.center)
                         
                         VStack(spacing: 6) {
                             Text(info.title)
                                 .font(.system(size: 16, weight: .bold, design: .rounded))
                                 .foregroundStyle(.white)
                             
                             Text("\"\(info.memoryLog)\"")
                                 .font(.system(size: 13, weight: .regular, design: .serif))
                                 .italic()
                                 .foregroundStyle(.white.opacity(0.8))
                                 .multilineTextAlignment(.center)
                                 .padding(.horizontal, 10)
                         }
                         
                         // Shards summary
                         HStack(spacing: 8) {
                             ForEach(1...3, id: \.self) { idx in
                                 HStack(spacing: 4) {
                                     Image(systemName: idx <= viewModel.levelShardsCollected ? "sparkle" : "sparkle")
                                         .foregroundStyle(idx <= viewModel.levelShardsCollected ? Color.yellow : Color.white.opacity(0.2))
                                 }
                             }
                             Text("(\(viewModel.levelShardsCollected)/3 Shards)")
                                 .font(.system(size: 11, weight: .bold, design: .monospaced))
                                 .foregroundStyle(.yellow)
                         }
                         .padding(6)
                         .background(.ultraThinMaterial)
                         .clipShape(Capsule())
                         
                         Divider().background(.white.opacity(0.2))
                         
                         Button(action: {
                             withAnimation {
                                 viewModel.startNextLevel(size: geo.size)
                             }
                         }) {
                             HStack(spacing: 8) {
                                 Image(systemName: "arrow.right.circle.fill")
                                     .font(.title2)
                                 Text("NEXT SECTOR")
                                     .font(.subheadline)
                                     .bold()
                             }
                             .foregroundStyle(info.sector.themeColor)
                             .padding(.horizontal, 24)
                             .padding(.vertical, 12)
                             .background(RoundedRectangle(cornerRadius: 16).fill(info.sector.themeColor.opacity(0.15)))
                         }
                     }
                     .padding(26)
                 }
                 .padding(.horizontal, 32)
             }
         }
         
         if viewModel.isPaused && !viewModel.showRevivePopup {
             ZStack {
                 Color.black.opacity(0.45).ignoresSafeArea()
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
                             
                             Button(action: { 
                                 viewModel.stopGame()
                                 onBack() 
                             }) {
                                 Image(systemName: "house.circle.fill")
                                     .font(.system(size: 50))
                                     .foregroundStyle(.white.opacity(0.5))
                             }
                         }
                     }
                     .padding(28)
                 }
                 .padding(.horizontal, 40)
             }
         }
    }
    
    // Drag Gesture & Double-Tap to Dash
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
                                    let halfWidth = viewModel.gameWidth / 2 - viewModel.playerRadius
                                    viewModel.playerX = min(max(newX, -halfWidth), halfWidth)
                                }
                                .onEnded { value in
                                    dragStartPlayerX = nil
                                    let distSq = value.translation.width * value.translation.width + value.translation.height * value.translation.height
                                    if distSq < 150 {
                                        let now = CACurrentMediaTime()
                                        if now - lastTapTime < 0.38 {
                                            viewModel.performDash()
                                            lastTapTime = 0
                                        } else {
                                            lastTapTime = now
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    viewModel.performDash()
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
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.top, 56)
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
                .position(x: geo.size.width / 2 + viewModel.playerX, y: geo.size.height - 60)
            
            ForEach(viewModel.obstacleRows.flatMap { $0.obstacles }) { obs in
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: obs.width * 0.3, height: 10)
                    .position(x: geo.size.width / 2 + obs.x, y: obs.y)
            }
        }
        .allowsHitTesting(false)
    }
}
