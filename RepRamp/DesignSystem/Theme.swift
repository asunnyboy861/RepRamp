import SwiftUI

enum Theme {
    static let background = Color(red: 14 / 255, green: 14 / 255, blue: 16 / 255)
    static let surface = Color(red: 26 / 255, green: 26 / 255, blue: 30 / 255)
    static let surfaceHigh = Color(red: 36 / 255, green: 36 / 255, blue: 42 / 255)
    static let orange = Color(red: 1.0, green: 90 / 255, blue: 31 / 255)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.68)
    static let textTertiary = Color(white: 0.45)
    static let separator = Color.white.opacity(0.08)
    static let success = Color(red: 0.30, green: 0.85, blue: 0.50)
    static let warning = Color(red: 1.0, green: 0.78, blue: 0.20)
    static let redHealth = Color(red: 0.92, green: 0.26, blue: 0.32)

    static func rankColor(_ rank: RepRank) -> Color {
        switch rank {
        case .unranked: return Color(white: 0.45)
        case .bronze: return Color(red: 0.72, green: 0.45, blue: 0.20)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.90, green: 0.89, blue: 0.87)
        case .diamond: return Color(red: 0.50, green: 0.86, blue: 1.0)
        case .master: return Color(red: 0.70, green: 0.42, blue: 1.0)
        case .legend: return Color(red: 1.0, green: 0.83, blue: 0.42)
        }
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 20 / 255, green: 20 / 255, blue: 24 / 255), background], startPoint: .top, endPoint: .bottom)
    }
}
