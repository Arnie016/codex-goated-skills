import SwiftUI
import VibeWidgetCore

struct DiscoveryLaneRow: View {
    let lane: DiscoveryLane
    let isPinned: Bool
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ScoutSymbolTile(symbol: lane.kind.systemImage, tint: accentColor)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(lane.kind.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if isPinned {
                        ScoutMoodPill(text: "Top", tint: accentColor)
                    }
                }

                Text(lane.recommendation.title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                Text("\(lane.recommendation.artist) • \(lane.recommendation.subtitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(lane.recommendation.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button(action: action) {
                Image(systemName: lane.recommendation.spotifyURI == nil ? "arrow.up.right" : "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.09).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }

    private var accentColor: Color {
        lane.kind.accentColor
    }
}

struct ScoutCompactPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.06, blue: 0.07).opacity(0.98),
                            Color(red: 0.03, green: 0.03, blue: 0.04).opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

struct ScoutToolbarButton: View {
    let symbol: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ScoutToolbarGlyph(symbol: symbol)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }
}

struct ScoutToolbarGlyph: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .semibold))
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}

struct ScoutToolbarProgress: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )

            ProgressView()
                .scaleEffect(0.72)
                .tint(.white.opacity(0.82))
        }
        .frame(width: 30, height: 30)
    }
}

struct ScoutPanelHeading: View {
    let symbol: String
    let title: String
    let subtitle: String
    var tint: Color = Color(red: 0.16, green: 0.64, blue: 0.36)

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ScoutSymbolTile(symbol: symbol, tint: tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

struct ScoutSymbolTile: View {
    let symbol: String
    var tint: Color = Color(red: 0.16, green: 0.64, blue: 0.36)

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(tint.opacity(0.14))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            )
    }
}

struct ScoutMoodPill: View {
    let text: String
    var tint: Color = Color(red: 0.18, green: 0.63, blue: 0.37)

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(tint.opacity(0.15))
            )
            .foregroundStyle(.white.opacity(0.92))
    }
}

struct ScoutRouteStatusCard: View {
    let status: AudioRouteStatus

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: routeSymbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 18, height: 18)
                .background(
                    Circle()
                        .fill(color.opacity(0.18))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(status.preferredOutput)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var label: String {
        switch status.availability {
        case .connected:
            return "Connected"
        case .available:
            return "Nearby"
        case .missing:
            return "Not found"
        }
    }

    private var routeSymbol: String {
        switch status.availability {
        case .connected:
            return "speaker.wave.2.fill"
        case .available:
            return "dot.radiowaves.left.and.right"
        case .missing:
            return "speaker.slash.fill"
        }
    }

    private var color: Color {
        switch status.availability {
        case .connected:
            return .green
        case .available:
            return .orange
        case .missing:
            return .red
        }
    }
}

struct ScoutFeaturedLaneCard: View {
    let lane: DiscoveryLane
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                ScoutSymbolTile(symbol: lane.kind.systemImage, tint: accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(lane.kind.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ScoutMoodPill(text: "Verified", tint: accentColor)
                    }

                    Text(lane.recommendation.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text("\(lane.recommendation.artist) • \(lane.recommendation.subtitle)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(lane.recommendation.reason)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: lane.recommendation.spotifyURI == nil ? "arrow.up.right" : "play.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.035))
            )
        }
        .buttonStyle(.plain)
    }

    private var accentColor: Color {
        lane.kind.accentColor
    }
}

private extension DiscoveryLaneKind {
    var accentColor: Color {
        let seed = tintSeed
        return Color(red: seed.0, green: seed.1, blue: seed.2)
    }
}
