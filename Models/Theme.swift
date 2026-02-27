import SwiftUI

struct Theme {
    static let primary = Color(hex: "8B5CF6")
    static let primaryLight = Color(hex: "DDD6FE")
    static let background = Color(hex: "F9FAFB")
    static let textMain = Color(hex: "1F2937")
    static let textSecondary = Color(hex: "6B7280")
    static let accent = Color(hex: "F59E0B")
    static let success = Color(hex: "10B981")

    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 16

    static func premiumIcon(_ name: String, color: Color = .primary) -> some View {
        Image(systemName: name)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
    }

    static func titleFont(size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func bodyFont(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
