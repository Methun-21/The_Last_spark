import SwiftUI

struct LevelSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    var onLevelSelected: (Int) -> Void
    var onBack: () -> Void
    
    @State private var selectedSector: BrainSector = .brainstem
    @State private var selectedLevelNumber: Int = 1
    
    var sectorLevels: [GameLevelInfo] {
        let range: ClosedRange<Int> = {
            switch selectedSector {
            case .brainstem: return 1...6
            case .hippocampus: return 7...12
            case .amygdala: return 13...18
            case .occipital: return 19...24
            case .prefrontal: return 25...30
            }
        }()
        return range.map { GameLevelInfo.info(for: $0) }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ParticleBackgroundView().opacity(0.3)
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("MEMORY ARCHIVES")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(.white.opacity(0.9))
                        Text("\(MemoryShardManager.shared.totalShardsCollected) / 90 Shards Recovered")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0).padding(12)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Sector Selector Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(BrainSector.allCases) { sector in
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedSector = sector
                                    if let first = sectorLevels.first {
                                        selectedLevelNumber = first.number
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: sector.icon)
                                        .font(.system(size: 12))
                                    Text(sector.name)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedSector == sector ? sector.themeColor.opacity(0.25) : Color.white.opacity(0.06))
                                .foregroundStyle(selectedSector == sector ? sector.themeColor : Color.white.opacity(0.6))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(selectedSector == sector ? sector.themeColor : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Horizontal Card Carousel for current sector
                TabView(selection: $selectedLevelNumber) {
                    ForEach(sectorLevels) { level in
                        LevelCard(
                            level: level,
                            isUnlocked: level.number <= viewModel.unlockedLevels,
                            shardsCollected: MemoryShardManager.shared.shardCount(for: level.number),
                            onPlay: {
                                onLevelSelected(level.number)
                            }
                        )
                        .tag(level.number)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Shard Count / Indicator Dots
                HStack(spacing: 8) {
                    ForEach(sectorLevels) { level in
                        Circle()
                            .fill(level.number == selectedLevelNumber ? selectedSector.themeColor : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            // Default to highest unlocked level's sector
            let current = min(viewModel.selectedLevel, 30)
            selectedLevelNumber = current
            selectedSector = GameLevelInfo.info(for: current).sector
        }
    }
}

struct LevelCard: View {
    let level: GameLevelInfo
    let isUnlocked: Bool
    let shardsCollected: Int
    var onPlay: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: isUnlocked ? [level.color, level.color.opacity(0.3)] : [.gray.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: isUnlocked ? level.color.opacity(0.35) : .clear, radius: 18)
            
            VStack(spacing: 16) {
                // Top Sector Tag & Shards
                HStack {
                    Text("CHAPTER \(level.number)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(isUnlocked ? level.color : .gray)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(1...3, id: \.self) { idx in
                            Image(systemName: idx <= shardsCollected ? "sparkle" : "sparkle")
                                .font(.system(size: 12))
                                .foregroundColor(idx <= shardsCollected ? .yellow : .white.opacity(0.2))
                        }
                    }
                }
                
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [level.color.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: isUnlocked ? level.icon : "lock.fill")
                        .font(.system(size: 32))
                        .foregroundColor(isUnlocked ? level.color : .gray)
                }
                
                // Titles
                VStack(spacing: 4) {
                    Text(level.title)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(isUnlocked ? .white : .gray)
                    
                    Text(level.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                // Memory Log / Lore Quote
                if isUnlocked {
                    Text("\"\(level.memoryLog)\"")
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                        .frame(height: 52)
                } else {
                    Text("Neural pathway locked. Restore preceding synapses to unlock.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(height: 52)
                }
                
                Spacer()
                
                // Target
                HStack {
                    Text("TARGET:")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("\(level.target) SYNAPSES")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(isUnlocked ? .white : .gray)
                }
                
                // Play Button
                Button(action: onPlay) {
                    HStack(spacing: 8) {
                        Text(isUnlocked ? "ENTER SYNAPSE" : "LOCKED")
                        if isUnlocked {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(isUnlocked ? .black : .white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isUnlocked ? level.color : Color.white.opacity(0.1))
                    .cornerRadius(18)
                    .shadow(color: isUnlocked ? level.color.opacity(0.5) : .clear, radius: 10)
                }
                .disabled(!isUnlocked)
            }
            .padding(24)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
    }
}
