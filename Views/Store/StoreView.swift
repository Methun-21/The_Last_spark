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
                    if selectedTab == .skins {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(storeManager.skins) { skin in
                                SkinCard(skin: skin, storeManager: storeManager)
                            }
                        }
                        .padding()
                        .padding(.bottom, 50)
                    } else if selectedTab == .backgrounds {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(storeManager.backgrounds) { bg in
                                BackgroundCard(bg: bg, storeManager: storeManager)
                            }
                        }
                        .padding()
                        .padding(.bottom, 50)
                    } else {
                        // Power-Ups — side-by-side equal cards
                        HStack(alignment: .top, spacing: 16) {
                            ReviveCard(storeManager: storeManager)
                            DashCard(storeManager: storeManager)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 50)
                    }
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

struct ReviveCard: View {
    @ObservedObject var storeManager: StoreManager

    var body: some View {
        ConsumableCard(
            icon: "heart.fill",
            iconColor: .pink,
            glowColor: .pink,
            title: "REVIVE",
            subtitle: "Restore 1 life\nin gameplay",
            count: storeManager.reviveCount,
            countColor: .pink,
            countIcon: "heart.fill",
            price: 1500,
            priceLabel: "1,500 SP",
            canAfford: storeManager.balance >= 1500
        ) {
            if storeManager.buyRevive() {
                AudioHapticManager.shared.playSound(named: "PowerUp")
                AudioHapticManager.shared.playSuccessHaptic()
            } else {
                AudioHapticManager.shared.playFailureHaptic()
            }
        }
    }
}

struct DashCard: View {
    @ObservedObject var storeManager: StoreManager

    var body: some View {
        ConsumableCard(
            icon: "bolt.horizontal.fill",
            iconColor: .cyan,
            glowColor: .cyan,
            title: "DASH",
            subtitle: "Phase through\nbarriers once",
            count: storeManager.dashCount,
            countColor: .cyan,
            countIcon: "bolt.fill",
            price: 600,
            priceLabel: "600 SP",
            canAfford: storeManager.balance >= 600
        ) {
            if storeManager.buyDash(price: 600) {
                AudioHapticManager.shared.playSound(named: "PowerUp")
                AudioHapticManager.shared.playSuccessHaptic()
            } else {
                AudioHapticManager.shared.playFailureHaptic()
            }
        }
    }
}

// MARK: - Shared symmetric consumable card

struct ConsumableCard: View {
    let icon: String
    let iconColor: Color
    let glowColor: Color
    let title: String
    let subtitle: String
    let count: Int
    let countColor: Color
    let countIcon: String
    let price: Int
    let priceLabel: String
    let canAfford: Bool
    let onBuy: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {

            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 76, height: 76)
                Circle()
                    .stroke(iconColor.opacity(0.28), lineWidth: 1.5)
                    .frame(width: 76, height: 76)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(iconColor)
                    .shadow(color: glowColor.opacity(0.9), radius: pulse ? 16 : 8)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                        value: pulse
                    )
            }
            .padding(.top, 22)
            .onAppear { pulse = true }

            // Title
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 12)

            // Subtitle
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
                .padding(.horizontal, 10)

            // Count pill
            HStack(spacing: 4) {
                if count == 0 {
                    Text("EMPTY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.gray)
                } else {
                    ForEach(0..<min(count, 4), id: \.self) { _ in
                        Image(systemName: countIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(countColor)
                    }
                    if count > 4 {
                        Text("+\(count - 4)")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(countColor)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(countColor.opacity(0.1))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(countColor.opacity(0.22), lineWidth: 1))
            .padding(.top, 14)

            Spacer(minLength: 14)

            // Buy button
            Button(action: onBuy) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(priceLabel)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(canAfford ? .black : .white.opacity(0.35))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    canAfford
                        ? AnyShapeStyle(iconColor)
                        : AnyShapeStyle(Color.white.opacity(0.07))
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canAfford)
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(iconColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: glowColor.opacity(0.14), radius: 18)
    }
}

typealias PowerUpCard = ReviveCard
