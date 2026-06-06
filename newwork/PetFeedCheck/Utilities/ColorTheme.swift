import SwiftUI

// MARK: - Color Theme — 暖橙金色系

enum PetColors {
    static let primary = Color(hex: "#F59E0B")       // amber-500
    static let primaryDark = Color(hex: "#D97706")    // amber-600
    static let primaryDeep = Color(hex: "#B45309")    // amber-700
    static let primaryLight = Color(hex: "#FCD34D")   // amber-300
    static let surfaceLight = Color(hex: "#FFFBEB")   // amber-50

    static let background = Color(hex: "#F8FAFC")     // slate-50
    static let cardBackground = Color.white
    static let textPrimary = Color(hex: "#1E293B")    // slate-800
    static let textSecondary = Color(hex: "#64748B")  // slate-500
    static let textTertiary = Color(hex: "#94A3B8")   // slate-400
    static let border = Color(hex: "#E2E8F0")         // slate-200

    static let success = Color(hex: "#10B981")        // emerald-500
    static let warning = Color(hex: "#F59E0B")
    static let error = Color(hex: "#EF4444")          // red-500
    static let info = Color(hex: "#3B82F6")           // blue-500
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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
