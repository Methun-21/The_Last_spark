import SwiftUI

struct LevelSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    var onLevelSelected: (Int) -> Void
    var onBack: () -> Void
    
    @State private var selectedTab = 0
    
    let levels = [
        GameLevelInfo(
            number: 1,
            title: "THE SIGNAL",
            subtitle: "Stabilization",
            target: 1000,
            description: "Stabilize the neural pulse. Establish a connection.",
            color: Color.cyan,
            icon: "waveform.path.ecg"
        ),
        GameLevelInfo(
            number: 2,
            title: "THE MEMORY",
            subtitle: "Reconnection",
            target: 2000,
            description: "Navigate the cortex. Restore fragmented memories.",
            color: Color.purple,
            icon: "brain.head.profile"
        ),
        GameLevelInfo(
            number: 3,
            title: "THE AWAKENING",
            subtitle: "Resurrection",
            target: 3000,
            description: "Break the cycle. Initiate full system wake-up.",
            color: Color.green,
            icon: "bolt.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Particle Background (Subtle)
            ParticleBackgroundView()
                .opacity(0.3)
            
            VStack {
                // Header
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    Spacer()
                    Text("MEMORY ARCHIVES")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    // Invisible spacer for balance
                    Image(systemName: "chevron.left").opacity(0).padding()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // Horizontal Scroll
                TabView(selection: $selectedTab) {
                    ForEach(0..<levels.count, id: \.self) { index in
                        LevelCard(
                            level: levels[index],
                            isUnlocked: index + 1 <= viewModel.unlockedLevels,
                            onPlay: {
                                onLevelSelected(levels[index].number)
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .frame(height: 500)
                
                Spacer()
                
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(0..<levels.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedTab ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct LevelCard: View {
    let level: GameLevelInfo
    let isUnlocked: Bool
    var onPlay: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Card Background
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                LinearGradient(
                                    colors: isUnlocked ? [level.color, level.color.opacity(0.3)] : [.gray.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: isUnlocked ? level.color.opacity(0.4) : .clear, radius: 20)
                
                VStack(spacing: 20) {
                    // Level Number
                    Text("CHAPTER 0\(level.number)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundColor(isUnlocked ? level.color : .gray)
                        .opacity(0.8)
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [level.color.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: isUnlocked ? level.icon : "lock.fill")
                            .font(.system(size: 40))
                            .foregroundColor(isUnlocked ? level.color : .gray)
                            .shadow(color: isUnlocked ? level.color : .clear, radius: 10)
                    }
                    .padding(.vertical, 10)
                    
                    // Title
                    VStack(spacing: 5) {
                        Text(level.title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(isUnlocked ? .white : .gray)
                            .shadow(color: isUnlocked ? level.color.opacity(0.5) : .clear, radius: 10)
                        
                        Text(level.subtitle)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, isUnlocked ? level.color.opacity(0.5) : .gray.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 1)
                        .padding(.vertical, 10)
                    
                    // Description
                    Text(level.description)
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .frame(height: 50)
                    
                    Spacer()
                    
                    // Target
                    HStack {
                        Text("TARGET:")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("\(level.target)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(isUnlocked ? .white : .gray)
                    }
                    .padding(.bottom, 10)
                    
                    // Play Button
                    Button(action: onPlay) {
                        HStack {
                            Text(isUnlocked ? "ENTER SIMULATION" : "LOCKED")
                            if isUnlocked {
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isUnlocked ? .black : .white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(isUnlocked ? level.color : Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .shadow(color: isUnlocked ? level.color.opacity(0.5) : .clear, radius: 10)
                    }
                    .disabled(!isUnlocked)
                }
                .padding(30)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            .contentShape(Rectangle()) // Make the whole area tappable
            .onTapGesture {
                if isUnlocked {
                    onPlay()
                }
            }
        }
    }
}


