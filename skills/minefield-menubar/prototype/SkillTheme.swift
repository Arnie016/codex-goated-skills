import SwiftUI

enum MinefieldTheme {
    static let accent = Color(red: 0.38, green: 0.93, blue: 0.62)
    static let accentSoft = Color(red: 0.71, green: 0.99, blue: 0.82)
    static let warning = Color(red: 0.94, green: 0.37, blue: 0.30)
    static let gold = Color(red: 0.96, green: 0.79, blue: 0.31)
    static let background = Color(red: 0.04, green: 0.06, blue: 0.08)
    static let panel = Color.white.opacity(0.06)
    static let panelStrong = Color.white.opacity(0.10)
    static let border = Color.white.opacity(0.12)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)

    static func numberColor(_ count: Int) -> Color {
        switch count {
        case 1:
            return Color(red: 0.43, green: 0.65, blue: 1.0)
        case 2:
            return accent
        case 3:
            return warning
        case 4:
            return Color(red: 0.72, green: 0.60, blue: 1.0)
        case 5:
            return Color(red: 1.0, green: 0.62, blue: 0.37)
        default:
            return Color(red: 0.86, green: 0.90, blue: 0.96)
        }
    }
}
