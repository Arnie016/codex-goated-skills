import SwiftUI

struct FlightScoutBackdrop: View {
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.035, blue: 0.045)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.12, blue: 0.18).opacity(0.42),
                    Color(red: 0.06, green: 0.07, blue: 0.09).opacity(0.14),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxHeight: .infinity, alignment: .top)

            RadialGradient(
                colors: [Color(red: 0.18, green: 0.23, blue: 0.34).opacity(0.12), .clear],
                center: .topLeading,
                startRadius: 6,
                endRadius: 220
            )
            .offset(x: -36, y: -44)
        }
    }
}

struct FlightScoutPanelSurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.048, green: 0.048, blue: 0.056).opacity(0.995))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.03),
                                    Color(red: 0.08, green: 0.1, blue: 0.16).opacity(0.1),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 52)
                        .mask(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                }
        )
        .shadow(color: .black.opacity(0.28), radius: 14, y: 8)
    }
}

struct FlightScoutSectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.075))
            .frame(height: 1)
            .padding(.vertical, 7)
    }
}

struct FlightScoutSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.3))
            .tracking(0.5)
            .textCase(.uppercase)
    }
}

struct FlightScoutBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(tint.opacity(0.11))
                    .overlay(
                        Capsule().stroke(tint.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

struct FlightScoutMenuRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 0)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.055 : 0.001))
            )
    }
}

struct FlightScoutTrailingIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.7 : 0.86))
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.08 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
    }
}

struct FlightScoutCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder var content: Content

    init(cornerRadius: CGFloat = 16, padding: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

struct FlightScoutPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(tint.opacity(0.12))
                    .overlay(
                        Capsule().stroke(tint.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundStyle(tint)
    }
}

struct FlightScoutSourcePill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.045))
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .foregroundStyle(Color.white.opacity(0.68))
    }
}

struct FlightScoutPrimaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [Color(red: 0.19, green: 0.34, blue: 0.66), Color(red: 0.23, green: 0.41, blue: 0.77)]
                                : [Color(red: 0.24, green: 0.42, blue: 0.78), Color(red: 0.29, green: 0.49, blue: 0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundStyle(.white)
    }
}

struct FlightScoutSecondaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.075 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .foregroundStyle(Color.white.opacity(0.88))
    }
}

struct FlightScoutFilterChip: View {
    let title: String
    let isSelected: Bool
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isSelected ? tint.opacity(0.11) : Color.white.opacity(0.03))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? tint.opacity(0.22) : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .foregroundStyle(isSelected ? tint : Color.white.opacity(0.72))
    }
}
