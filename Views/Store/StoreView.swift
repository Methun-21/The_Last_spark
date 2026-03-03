import SwiftUI

public struct StoreView: View {
    @StateObject var storeManager = StoreManager.shared
    var onBack: () -> Void
    var initialTab: StoreTab = .skins
    
    @State private var selectedTab: StoreTab
    
    public init(onBack: @escaping () -> Void, initialTab: StoreTab = .skins) {
        self.onBack = onBack
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }
    
    public    enum StoreTab: String, CaseIterable {
        case skins = "SKINS"
        case backgrounds = "AMBIENCE"
        case powerUps = "POWER-UPS"
    }
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 20)
    ]
    
    public var body: some View {
        ZStack {
            // Background
            AtmosphericBackground()
            
            VStack(spacing: 0) {
                // Header (Bento Style)
                HStack {
                    Button(action: {
                        AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
                        onBack()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("CYBERNETICS LAB")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Currency Badge
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("\(storeManager.balance)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Tab Selection
                HStack(spacing: 0) {
                    TabButton(title: "NEURAL SKINS", isSelected: selectedTab == .skins) {
                        selectedTab = .skins
                    }
                    
                    TabButton(title: "ENVIRONMENTS", isSelected: selectedTab == .backgrounds) {
                        selectedTab = .backgrounds
                    }
                    
                    TabButton(title: "POWER-UPS", isSelected: selectedTab == .powerUps) {
                        selectedTab = .powerUps
                    }
                }
                .padding(4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        if selectedTab == .skins {
                            ForEach(storeManager.skins) { skin in
                                SkinCard(skin: skin, storeManager: storeManager)
                            }
                        } else if selectedTab == .backgrounds {
                            ForEach(storeManager.backgrounds) { bg in
                                BackgroundCard(bg: bg, storeManager: storeManager)
                            }
                        } else {
                            // Power-Ups Section
                            PowerUpCard(storeManager: storeManager)
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SkinCard: View {
    let skin: PlayerSkin
    @ObservedObject var storeManager: StoreManager
    
    var isUnlocked: Bool {
        storeManager.unlockedSkins.contains(skin.id)
    }
    
    var isEquipped: Bool {
        storeManager.selectedSkinID == skin.id
    }
    
    var body: some View {
        BentoCard {
            VStack(spacing: 12) {
                // Preview
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    PlayerView(skinColor: storeManager.getColor(for: skin.id))
                        .frame(width: 60, height: 60)
                    
                    if isEquipped {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                            .background(Circle().fill(Color.white))
                            .offset(x: 30, y: -30)
                    }
                }
                .padding(.top, 10)
                
                // Name
                Text(skin.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Action Button
                Button(action: {
                    if isUnlocked {
                        storeManager.equipSkin(skin)
                        AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
                    } else {
                        storeManager.buySkin(skin)
                        AudioHapticManager.shared.playSound(named: "PowerUp")
                    }
                }) {
                    Text(buttonText)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(buttonTextColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(buttonBgColor)
                        .clipShape(Capsule())
                }
                .disabled(isEquipped || (!isUnlocked && storeManager.balance < skin.price))
                .opacity(isEquipped ? 0.6 : 1.0)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    var buttonText: String {
        if isUnlocked {
            return isEquipped ? "EQUIPPED" : "EQUIP"
        } else {
            return "\(skin.price) SP"
        }
    }
    
    var buttonBgColor: Color {
        if isUnlocked {
            return isEquipped ? .gray.opacity(0.3) : .white
        } else {
            return storeManager.balance >= skin.price ? .yellow : .gray.opacity(0.3)
        }
    }
    
    var buttonTextColor: Color {
        if isUnlocked {
            return isEquipped ? .white : .black
        } else {
            return storeManager.balance >= skin.price ? .black : .white.opacity(0.5)
        }
    }
}

struct BackgroundCard: View {
    let bg: GameBackground
    @ObservedObject var storeManager: StoreManager
    
    var isUnlocked: Bool {
        storeManager.unlockedBackgrounds.contains(bg.id)
    }
    
    var isEquipped: Bool {
        storeManager.selectedBackgroundID == bg.id
    }
    
    var body: some View {
        BentoCard {
            VStack(spacing: 12) {
                // Preview
                ZStack {
                    storeManager.getGradient(for: bg.id)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    
                    if isEquipped {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                            .background(Circle().fill(Color.white))
                            .offset(x: 30, y: -30)
                    }
                }
                .padding(.top, 10)
                
                // Name
                Text(bg.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Action Button
                Button(action: {
                    if isUnlocked {
                        storeManager.equipBackground(bg)
                        AudioHapticManager.shared.playSound(named: "ScoreMultiplier")
                    } else {
                        storeManager.buyBackground(bg)
                        AudioHapticManager.shared.playSound(named: "PowerUp")
                    }
                }) {
                    Text(buttonText)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(buttonTextColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(buttonBgColor)
                        .clipShape(Capsule())
                }
                .disabled(isEquipped || (!isUnlocked && storeManager.balance < bg.price))
                .opacity(isEquipped ? 0.6 : 1.0)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    var buttonText: String {
        if isUnlocked {
            return isEquipped ? "EQUIPPED" : "EQUIP"
        } else {
            return "\(bg.price) SP"
        }
    }
    
    var buttonBgColor: Color {
        if isUnlocked {
            return isEquipped ? .gray.opacity(0.3) : .white
        } else {
            return storeManager.balance >= bg.price ? .yellow : .gray.opacity(0.3)
        }
    }
    
    var buttonTextColor: Color {
        if isUnlocked {
            return isEquipped ? .white : .black
        } else {
            return storeManager.balance >= bg.price ? .black : .white.opacity(0.5)
        }
    }
}

struct PowerUpCard: View {
    @ObservedObject var storeManager: StoreManager
    
    var body: some View {
        BentoCard {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.pink.opacity(0.8), Color.red],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 5)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                        .shadow(color: .pink, radius: 10)
                }
                .padding(.top, 20)
                
                // Title
                Text("REVIVE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Description
                Text("Restore 1 life during gameplay")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                // Inventory Count
                HStack(spacing: 6) {
                    Image(systemName: "cube.box.fill")
                        .foregroundStyle(.cyan)
                    Text("Owned: \(storeManager.reviveCount)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                
                // Buy Button
                Button(action: {
                    if storeManager.buyRevive() {
                        AudioHapticManager.shared.playSound(named: "PowerUp")
                        AudioHapticManager.shared.playSuccessHaptic()
                    } else {
                        AudioHapticManager.shared.playFailureHaptic()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                        Text("1500 SP")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(storeManager.balance >= 1500 ? .black : .white.opacity(0.5))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(storeManager.balance >= 1500 ? Color.yellow : Color.gray.opacity(0.3))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
