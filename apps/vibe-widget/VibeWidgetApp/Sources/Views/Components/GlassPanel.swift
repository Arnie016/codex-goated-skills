import SwiftUI
import VibeWidgetCore

enum VibeTheme {
    static let backgroundTop = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let backgroundBottom = Color(red: 0.08, green: 0.09, blue: 0.12)
    static let panel = Color(red: 0.10, green: 0.12, blue: 0.16).opacity(0.96)
    static let panelRaised = Color(red: 0.13, green: 0.15, blue: 0.20).opacity(0.96)
    static let border = Color.white.opacity(0.08)
    static let primaryText = Color.white.opacity(0.96)
    static let secondaryText = Color(red: 0.80, green: 0.84, blue: 0.90)
    static let tertiaryText = Color.white.opacity(0.58)
    static let accent = Color(red: 0.35, green: 0.60, blue: 0.86)
    static let warmAccent = Color(red: 0.77, green: 0.56, blue: 0.33)
}

struct GlassPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(VibeTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(VibeTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.22), radius: 24, y: 12)
    }
}

struct VibeBackdrop: View {
    var secondaryOnly: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [VibeTheme.backgroundTop, VibeTheme.backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Circle()
                .fill(VibeTheme.accent.opacity(secondaryOnly ? 0.08 : 0.16))
                .blur(radius: 34)
                .frame(width: 360, height: 360)
                .offset(x: -340, y: -220)

            Circle()
                .fill(VibeTheme.warmAccent.opacity(secondaryOnly ? 0.06 : 0.12))
                .blur(radius: 52)
                .frame(width: 420, height: 420)
                .offset(x: 320, y: 220)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(VibeTheme.primaryText)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(VibeTheme.primaryText)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(VibeTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(VibeTheme.panelRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(VibeTheme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    let title: String
    let subtitle: String
    let availability: AudioRouteAvailability

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(VibeTheme.primaryText)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(VibeTheme.secondaryText)
            Text(label)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(color.opacity(0.18))
                )
                .foregroundStyle(color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(VibeTheme.panelRaised)
        )
    }

    private var label: String {
        switch availability {
        case .connected:
            return "Connected"
        case .available:
            return "Available"
        case .missing:
            return "Not Found"
        }
    }

    private var color: Color {
        switch availability {
        case .connected:
            return Color.green
        case .available:
            return Color.orange
        case .missing:
            return Color.red
        }
    }
}

struct RecommendationRow: View {
    let recommendation: VibeRecommendation
    let isPinned: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.15, green: 0.49, blue: 0.73), Color(red: 0.73, green: 0.44, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 64, height: 64)
                .overlay(Image(systemName: isPinned ? "sparkles" : "music.note").font(.title2.weight(.bold)))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundStyle(VibeTheme.primaryText)
                    if isPinned {
                        Text("PINNED")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(VibeTheme.border))
                            .foregroundStyle(VibeTheme.primaryText)
                    }
                }
                Text("\(recommendation.artist) • \(recommendation.subtitle)")
                    .foregroundStyle(VibeTheme.secondaryText)
                Text(recommendation.reason)
                    .font(.footnote)
                    .foregroundStyle(VibeTheme.tertiaryText)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PermissionDot: View {
    let state: PermissionSnapshot.State
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption.weight(.bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(VibeTheme.panelRaised))
        .foregroundStyle(VibeTheme.primaryText)
    }

    private var color: Color {
        switch state {
        case .granted:
            return .green
        case .denied:
            return .red
        case .unknown:
            return .orange
        }
    }
}
