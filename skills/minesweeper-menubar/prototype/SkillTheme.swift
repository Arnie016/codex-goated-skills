import SwiftUI

enum MinesweeperTheme {
    static let accent = Color(red: 0.48, green: 0.94, blue: 0.69)
    static let accentSoft = Color(red: 0.84, green: 1.0, blue: 0.91)
    static let warning = Color(red: 0.93, green: 0.36, blue: 0.31)
    static let caution = Color(red: 0.95, green: 0.76, blue: 0.30)
    static let background = Color(red: 0.04, green: 0.06, blue: 0.08)
    static let panel = Color.white.opacity(0.06)
    static let panelStrong = Color.white.opacity(0.10)
    static let border = Color.white.opacity(0.12)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)

    static func numberColor(_ count: Int) -> Color {
        switch count {
        case 1:
            return Color(red: 0.46, green: 0.66, blue: 1.0)
        case 2:
            return accent
        case 3:
            return warning
        case 4:
            return Color(red: 0.75, green: 0.62, blue: 1.0)
        case 5:
            return Color(red: 1.0, green: 0.64, blue: 0.40)
        default:
            return Color(red: 0.86, green: 0.90, blue: 0.95)
        }
    }
}
