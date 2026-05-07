import SwiftUI

enum SecuritySentryLevel: Equatable {
    case safe
    case warning
    case danger

    var color: Color {
        switch self {
        case .safe: return SecuritySentryTheme.safe
        case .warning: return SecuritySentryTheme.warning
        case .danger: return SecuritySentryTheme.danger
        }
    }

    var symbol: String {
        switch self {
        case .safe: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .danger: return "exclamationmark.triangle.fill"
        }
    }
}

struct SecuritySentrySection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let count: Int
    let level: SecuritySentryLevel
}

struct SecuritySentryDetailView: View {
    let sections: [SecuritySentrySection]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(sections) { section in
                HStack(spacing: 10) {
                    Image(systemName: section.level.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(section.level.color)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(section.title)
                            .font(.headline)
                            .foregroundStyle(SecuritySentryTheme.textPrimary)
                        Text(section.subtitle)
                            .font(.caption)
                            .foregroundStyle(SecuritySentryTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 12)

                    Text("\(section.count)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(section.level.color)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(12)
                .background(SecuritySentryTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(SecuritySentryTheme.border, lineWidth: 1)
                )
            }
        }
    }
}

extension SecuritySentryDetailView {
    static var previewSections: [SecuritySentrySection] {
        [
            SecuritySentrySection(title: "Network Connections", subtitle: "23 established, 2 non-web ports", count: 23, level: .warning),
            SecuritySentrySection(title: "Listening Ports", subtitle: "One unexpected high port", count: 7, level: .warning),
            SecuritySentrySection(title: "LaunchAgents", subtitle: "No recent plist edits", count: 14, level: .safe),
            SecuritySentrySection(title: "Processes", subtitle: "No unusual executable paths", count: 20, level: .safe),
            SecuritySentrySection(title: "Recent Files", subtitle: "Finder-safe changes only", count: 18, level: .safe)
        ]
    }
}
