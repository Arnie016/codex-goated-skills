import SwiftUI

enum OnThisDayPalette {
    static let panel = Color(red: 0.09, green: 0.13, blue: 0.20)
    static let raised = Color.white.opacity(0.05)
    static let border = Color.white.opacity(0.09)
    static let accent = Color(red: 0.84, green: 0.54, blue: 0.18)
    static let accentSoft = Color(red: 0.53, green: 0.84, blue: 1.0)
    static let success = Color(red: 0.31, green: 0.89, blue: 0.63)
    static let warning = Color(red: 0.99, green: 0.73, blue: 0.36)
    static let danger = Color(red: 1.0, green: 0.58, blue: 0.56)
    static let primaryText = Color.white.opacity(0.97)
    static let secondaryText = Color.white.opacity(0.64)
    static let mutedText = Color.white.opacity(0.4)
}

struct OnThisDayBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.15),
                    Color(red: 0.03, green: 0.05, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(red: 0.31, green: 0.63, blue: 1.0).opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 38)
                .offset(x: -110, y: -180)

            Circle()
                .fill(OnThisDayPalette.accent.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 48)
                .offset(x: 130, y: 180)
        }
        .ignoresSafeArea()
    }
}

struct OnThisDayCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.055), Color.white.opacity(0.028)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(OnThisDayPalette.panel.opacity(0.96))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(OnThisDayPalette.border, lineWidth: 1)
                )
        )
    }
}

struct OnThisDayStatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.16))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(tint.opacity(0.34), lineWidth: 1)
                    )
            )
            .foregroundStyle(tint)
    }
}

struct OnThisDayMetricTile: View {
    let metric: OnThisDayMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(metric.title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(OnThisDayPalette.mutedText)
            Text(metric.value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(OnThisDayPalette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(metric.detail)
                .font(.system(size: 10.5))
                .foregroundStyle(OnThisDayPalette.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(OnThisDayPalette.raised)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(OnThisDayPalette.border, lineWidth: 1)
                )
        )
    }
}

struct OnThisDayKindButton: View {
    let kind: OnThisDayFeedKind
    let count: Int
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isActive ? OnThisDayPalette.accentSoft : Color.white.opacity(0.16))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(OnThisDayPalette.primaryText)
                    Text(kind.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(OnThisDayPalette.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text("\(count)")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(isActive ? OnThisDayPalette.primaryText : OnThisDayPalette.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(isActive ? 0.10 : 0.04))
                    )
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? OnThisDayPalette.accentSoft.opacity(0.13) : Color.white.opacity(0.035))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isActive ? OnThisDayPalette.accentSoft.opacity(0.35) : OnThisDayPalette.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct OnThisDayEntryRow: View {
    let entry: OnThisDayEntry
    let kindTitle: String
    let openAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.yearLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(OnThisDayPalette.accentSoft)
                    Spacer(minLength: 0)
                    Text(kindTitle)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(OnThisDayPalette.secondaryText)
                }

                Text(entry.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OnThisDayPalette.primaryText)
                    .lineLimit(2)

                Text(entry.text)
                    .font(.system(size: 11.5))
                    .foregroundStyle(OnThisDayPalette.secondaryText)
                    .lineLimit(3)

                if !entry.pageTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(entry.pageTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundStyle(OnThisDayPalette.secondaryText)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color.white.opacity(0.05))
                                    )
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    Text(entry.detail)
                        .font(.system(size: 10))
                        .foregroundStyle(OnThisDayPalette.mutedText)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Button("Open") {
                        openAction()
                    }
                    .buttonStyle(OnThisDaySecondaryButtonStyle())
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))

                if let imageURL = entry.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(entry.yearLabel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(OnThisDayPalette.secondaryText)
                    }
                } else {
                    Text(entry.yearLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(OnThisDayPalette.secondaryText)
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(OnThisDayPalette.border, lineWidth: 1)
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(OnThisDayPalette.border, lineWidth: 1)
                )
        )
    }
}

struct OnThisDayPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(OnThisDayPalette.accent.opacity(configuration.isPressed ? 0.7 : 0.92))
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct OnThisDaySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.09 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(OnThisDayPalette.border, lineWidth: 1)
                    )
            )
            .foregroundStyle(OnThisDayPalette.primaryText)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}
