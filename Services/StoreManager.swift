import SwiftUI
import Combine

public struct PlayerSkin: Identifiable, Codable {
    public let id: String
    public let name: String
    public let color: String // Hex or description for now, simpler
    public let price: Int
}

public struct GameBackground: Identifiable, Codable {
    public let id: String
    public let name: String
    public let colors: [String] // 2 colors for gradient
    public let price: Int
}

public class StoreManager: ObservableObject {
    public static let shared = StoreManager()
    
    @Published public var balance: Int {
        didSet { UserDefaults.standard.set(balance, forKey: "synapseBalance") }
    }
    
    // Inventory
    @Published public var unlockedSkins: [String] = []
    @Published public var unlockedBackgrounds: [String] = []
    
    // Selection
    @Published public var selectedSkinID: String {
        didSet { UserDefaults.standard.set(selectedSkinID, forKey: "selectedSkin") }
    }
    @Published public var selectedBackgroundID: String {
        didSet { UserDefaults.standard.set(selectedBackgroundID, forKey: "selectedBackground") }
    }
    
    // Consumables
    @Published public var reviveCount: Int {
        didSet { UserDefaults.standard.set(reviveCount, forKey: "reviveCount") }
    }
    @Published public var dashCount: Int {
        didSet { UserDefaults.standard.set(dashCount, forKey: "dashCount") }
    }
    
    // Catalog
    public let skins: [PlayerSkin] = [
        PlayerSkin(id: "default_white", name: "Pure Spark", color: "white", price: 0),
        PlayerSkin(id: "cyan_pulse", name: "Cyan Pulse", color: "cyan", price: 2000),
        PlayerSkin(id: "golden_glitch", name: "Gold Glitch", color: "yellow", price: 5000),
        PlayerSkin(id: "crimson_virus", name: "Red Virus", color: "red", price: 10000),
        PlayerSkin(id: "void_shadow", name: "Void Walker", color: "purple", price: 25000)
    ]
    
    public let backgrounds: [GameBackground] = [
        GameBackground(id: "default_space", name: "Deep Space", colors: ["#0f0c29", "#302b63"], price: 0),
        GameBackground(id: "cyber_city", name: "Neon City", colors: ["#200122", "#6f0000"], price: 5000),
        GameBackground(id: "mind_ocean", name: "Mind Ocean", colors: ["#1A2980", "#26D0CE"], price: 8000),
        GameBackground(id: "matrix_code", name: "The Grid", colors: ["#000000", "#0f9b0f"], price: 15000)
    ]
    
    private init() {
        self.balance = UserDefaults.standard.integer(forKey: "synapseBalance")
        self.reviveCount = UserDefaults.standard.integer(forKey: "reviveCount")
        
        // Initial starter dashes (3) if fresh install
        if UserDefaults.standard.object(forKey: "dashCount") == nil {
            self.dashCount = 3
            UserDefaults.standard.set(3, forKey: "dashCount")
        } else {
            self.dashCount = UserDefaults.standard.integer(forKey: "dashCount")
        }
        
        // Convert old unlockedThemes to new system if needed, or just reset for new version
        // Using "unlockedSkins" and "unlockedBackgrounds" keys
        self.unlockedSkins = UserDefaults.standard.stringArray(forKey: "unlockedSkins") ?? ["default_white"]
        self.unlockedBackgrounds = UserDefaults.standard.stringArray(forKey: "unlockedBackgrounds") ?? ["default_space"]
        
        self.selectedSkinID = UserDefaults.standard.string(forKey: "selectedSkin") ?? "default_white"
        self.selectedBackgroundID = UserDefaults.standard.string(forKey: "selectedBackground") ?? "default_space"
    }
    
    public func buySkin(_ skin: PlayerSkin) {
        if balance >= skin.price {
            balance -= skin.price
            unlockedSkins.append(skin.id)
            UserDefaults.standard.set(unlockedSkins, forKey: "unlockedSkins")
        }
    }
    
    public func buyBackground(_ bg: GameBackground) {
        if balance >= bg.price {
            balance -= bg.price
            unlockedBackgrounds.append(bg.id)
            UserDefaults.standard.set(unlockedBackgrounds, forKey: "unlockedBackgrounds")
        }
    }
    
    public func equipSkin(_ skin: PlayerSkin) {
        selectedSkinID = skin.id
    }
    
    public func equipBackground(_ bg: GameBackground) {
        selectedBackgroundID = bg.id
    }
    
    // Consumable Management
    public func buyRevive(price: Int = 1500) -> Bool {
        if balance >= price {
            balance -= price
            reviveCount += 1
            return true
        }
        return false
    }
    
    public func useRevive() -> Bool {
        if reviveCount > 0 {
            reviveCount -= 1
            return true
        }
        return false
    }
    
    public func buyDash(price: Int = 600) -> Bool {
        if balance >= price {
            balance -= price
            dashCount += 1
            return true
        }
        return false
    }
    
    public func useDash() -> Bool {
        if dashCount > 0 {
            dashCount -= 1
            return true
        }
        return false
    }
    
    public func addDash(_ amount: Int = 1) {
        dashCount += amount
    }
    
    public func getColor(for skinID: String) -> Color {
        guard let skin = skins.first(where: { $0.id == skinID }) else { return .white } // Default
        switch skin.color {
        case "cyan": return .cyan
        case "yellow": return .yellow
        case "red": return .red
        case "purple": return .purple
        default: return .white
        }
    }
    
    public func getGradient(for bgID: String) -> LinearGradient {
        guard let bg = backgrounds.first(where: { $0.id == bgID }) else {
            return LinearGradient(colors: [Color.black, Color.blue.opacity(0.3)], startPoint: .top, endPoint: .bottom)
        }
        
        // Simple hex mapping helper (simulated)
        let colors: [Color]
        switch bg.id {
        case "cyber_city": colors = [Color.black, Color.red.opacity(0.3)]
        case "mind_ocean": colors = [Color(red: 0.1, green: 0.2, blue: 0.5), Color.cyan.opacity(0.4)]
        case "matrix_code": colors = [Color.black, Color.green.opacity(0.2)]
        default: colors = [Color(red: 0.05, green: 0.05, blue: 0.2), Color.black] // Deep Space
        }
        
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
}
