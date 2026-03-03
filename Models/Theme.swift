import SwiftUI

struct Theme: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var price: Int
    var primaryColorHex: String // Hex string for Codable support
    var secondaryColorHex: String
    
    var primaryColor: Color {
        Color(hex: primaryColorHex) ?? .cyan
    }
    
    var secondaryColor: Color {
        Color(hex: secondaryColorHex) ?? .blue
    }
    
    static let allThemes: [Theme] = [
        Theme(id: "cyan_neon", name: "Cyber Cyan", price: 0, primaryColorHex: "#00FFFF", secondaryColorHex: "#0000FF"),
        Theme(id: "neon_purple", name: "Synthwave Purple", price: 500, primaryColorHex: "#A020F0", secondaryColorHex: "#FF00FF"),
        Theme(id: "matrix_green", name: "Matrix Green", price: 1000, primaryColorHex: "#00FF00", secondaryColorHex: "#006400"),
        Theme(id: "danger_red", name: "Crimson Alert", price: 2000, primaryColorHex: "#FF0000", secondaryColorHex: "#8B0000"),
        Theme(id: "golden_spark", name: "Golden Spark", price: 5000, primaryColorHex: "#FFD700", secondaryColorHex: "#FFA500")
    ]
}

// Helper extension for Color <-> Hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
