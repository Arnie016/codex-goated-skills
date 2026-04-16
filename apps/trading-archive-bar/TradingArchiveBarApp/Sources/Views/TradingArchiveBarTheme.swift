import SwiftUI

enum TradingArchivePalette {
    static let backgroundTop = Color(red: 0.07, green: 0.09, blue: 0.13)
    static let backgroundBottom = Color(red: 0.03, green: 0.04, blue: 0.06)
    static let card = Color.white.opacity(0.06)
    static let cardStrong = Color.white.opacity(0.09)
    static let border = Color.white.opacity(0.08)
    static let accent = Color(red: 0.27, green: 0.73, blue: 0.58)
    static let accentSoft = Color(red: 0.35, green: 0.77, blue: 0.68)
    static let warning = Color(red: 0.94, green: 0.74, blue: 0.28)
    static let danger = Color(red: 0.92, green: 0.42, blue: 0.43)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let mutedText = Color.white.opacity(0.45)
}

struct TradingArchiveBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [TradingArchivePalette.backgroundTop, TradingArchivePalette.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(TradingArchivePalette.accent.opacity(0.14))
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .offset(x: 50, y: -50)
        }
    }
}

struct TradingArchiveCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(TradingArchivePalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(TradingArchivePalette.border, lineWidth: 1)
                )
        )
    }
}

struct TradingArchiveMetricTile: View {
    let metric: TradingArchiveMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(metric.title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(TradingArchivePalette.mutedText)
            Text(metric.value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(TradingArchivePalette.primaryText)
            Text(metric.detail)
                .font(.system(size: 10.5))
                .foregroundStyle(TradingArchivePalette.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(TradingArchivePalette.cardStrong)
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(TradingArchivePalette.border, lineWidth: 1)
                )
        )
    }
}

struct TradingArchiveStatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule(style: .continuous).fill(tint))
    }
}

struct TradingArchiveWindowButton: View {
    let window: TradingArchiveWindow
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(window.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isActive ? .white : TradingArchivePalette.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(isActive ? TradingArchivePalette.accent : Color.white.opacity(0.05))
                )
        }
        .buttonStyle(.plain)
    }
}

struct TradingArchiveSourceBadge: View {
    let status: TradingArchiveSourceStatus
    let action: () -> Void

    private var tint: Color {
        switch status.health {
        case .live:
            return TradingArchivePalette.accent
        case .cached:
            return TradingArchivePalette.warning
        case .failed:
            return TradingArchivePalette.danger
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(tint)
                        .frame(width: 7, height: 7)
                    Text(status.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TradingArchivePalette.primaryText)
                        .lineLimit(1)
                }
                Text("\(status.articleCount) articles • \(status.health.title)")
                    .font(.system(size: 10.5))
                    .foregroundStyle(TradingArchivePalette.secondaryText)
                    .lineLimit(2)
            }
            .frame(width: 140, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(TradingArchivePalette.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct TradingArchiveArticleRow: View {
    let article: TradingArchiveArticle
    let isFavorite: Bool
    let favoriteAction: () -> Void
    let openAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(article.title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(TradingArchivePalette.primaryText)
                        .lineLimit(2)

                    Text(article.summary.isEmpty ? "Open the article for the full read." : article.summary)
                        .font(.system(size: 11))
                        .foregroundStyle(TradingArchivePalette.secondaryText)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)

                Button(action: favoriteAction) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isFavorite ? TradingArchivePalette.warning : TradingArchivePalette.secondaryText)
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.05)))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                TradingArchiveStatusPill(title: article.sourceName, tint: TradingArchivePalette.cardStrong)
                Text(article.publishedLabel)
                    .font(.system(size: 10.5))
                    .foregroundStyle(TradingArchivePalette.secondaryText)
                Spacer(minLength: 0)
                Button("Open", action: openAction)
                    .buttonStyle(TradingArchiveSecondaryButtonStyle())
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TradingArchivePalette.border, lineWidth: 1)
                )
        )
    }
}

struct TradingArchivePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(TradingArchivePalette.accent.opacity(configuration.isPressed ? 0.75 : 1))
            )
    }
}

struct TradingArchiveSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(TradingArchivePalette.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(TradingArchivePalette.border, lineWidth: 1)
                    )
            )
    }
}
