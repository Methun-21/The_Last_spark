import SwiftUI

struct ProfileView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @ObservedObject var shardManager = MemoryShardManager.shared
    @Binding var isPresented: Bool
    
    // Settings state
    @State private var musicEnabled = AudioHapticManager.shared.isMusicEnabled
    @State private var sfxEnabled = AudioHapticManager.shared.isSFXEnabled
    @State private var hapticsEnabled = AudioHapticManager.shared.isHapticsEnabled
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    // MARK: - Profile Stats & Subject Status
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SUBJECT #734")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.white)
                                
                                let currentSector = GameLevelInfo.info(for: min(gameViewModel.unlockedLevels, 30)).sector
                                Text("Awakening: \(currentSector.name)")
                                    .font(.caption)
                                    .foregroundStyle(currentSector.themeColor)
                            }
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.white.opacity(0.05))
                        
                        statRow(icon: "bolt.fill", color: .yellow, title: "Total Synapses", value: "\(StoreManager.shared.balance)")
                        statRow(icon: "sparkle", color: .yellow, title: "Memory Shards", value: "\(shardManager.totalShardsCollected) / 90")
                        statRow(icon: "crown.fill", color: .orange, title: "High Score", value: "\(gameViewModel.highScore)")
                        
                        // Level Progress Indicator
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Neural Restoration")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("\(gameViewModel.unlockedLevels)/30 Chapters")
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(.cyan)
                            }
                            
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.1))
                                    Capsule()
                                        .fill(LinearGradient(colors: [.cyan, .purple, .mint], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: g.size.width * (CGFloat(min(gameViewModel.unlockedLevels, 30)) / 30.0))
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("SUBJECT VITALS & RECOVERY")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    // MARK: - Recovered Memory Logs (Emotional Lore)
                    Section {
                        ForEach(1...min(gameViewModel.unlockedLevels, 30), id: \.self) { lvl in
                            let info = GameLevelInfo.info(for: lvl)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("CH. \(lvl) • \(info.title)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(info.sector.themeColor)
                                    Spacer()
                                    let count = shardManager.shardCount(for: lvl)
                                    HStack(spacing: 2) {
                                        ForEach(1...3, id: \.self) { idx in
                                            Image(systemName: idx <= count ? "sparkle" : "sparkle")
                                                .font(.system(size: 9))
                                                .foregroundStyle(idx <= count ? Color.yellow : Color.white.opacity(0.2))
                                        }
                                    }
                                }
                                Text("\"\(info.memoryLog)\"")
                                    .font(.system(size: 13, weight: .regular, design: .serif))
                                    .italic()
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    } header: {
                        Text("RECOVERED MEMORY ARCHIVES")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    // MARK: - Settings
                    Section {
                        Toggle(isOn: $musicEnabled) {
                            Label {
                                Text("Music")
                                    .foregroundStyle(.white)
                            } icon: {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.pink)
                            }
                        }
                        .tint(.pink)
                        .onChange(of: musicEnabled) { newValue in
                            AudioHapticManager.shared.isMusicEnabled = newValue
                            if !newValue {
                                AudioHapticManager.shared.pauseBackgroundMusic()
                            } else {
                                AudioHapticManager.shared.playBackgroundMusic(named: "neural_pulse", withExtension: "mp3")
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                        
                        Toggle(isOn: $sfxEnabled) {
                            Label {
                                Text("Sound Effects")
                                    .foregroundStyle(.white)
                            } icon: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.pink)
                            }
                        }
                        .tint(.pink)
                        .onChange(of: sfxEnabled) { newValue in
                            AudioHapticManager.shared.isSFXEnabled = newValue
                            if newValue {
                                AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                        
                        Toggle(isOn: $hapticsEnabled) {
                            Label {
                                Text("Haptic Feedback")
                                    .foregroundStyle(.white)
                            } icon: {
                                Image(systemName: "iphone.gen3")
                                    .foregroundStyle(.green)
                            }
                        }
                        .tint(.green)
                        .onChange(of: hapticsEnabled) { newValue in
                            AudioHapticManager.shared.isHapticsEnabled = newValue
                            AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
                            AudioHapticManager.shared.playUITap(style: .medium)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                        
                    } header: {
                        Text("SYSTEM SETTINGS")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    // MARK: - About
                    Section {
                        NavigationLink(destination: LicensesView()) {
                            Label {
                                Text("Licenses & Attributions")
                                    .foregroundStyle(.white)
                            } icon: {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                        
                        HStack {
                            Text("Version")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("2.0 (Pro Edition)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("ABOUT")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Subject Profile & Lore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func statRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .bold()
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}
