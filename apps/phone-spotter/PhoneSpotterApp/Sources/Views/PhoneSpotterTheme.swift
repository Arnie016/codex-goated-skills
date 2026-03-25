import AppKit
import SwiftUI

struct PhoneSpotterBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.11),
                    Color(red: 0.11, green: 0.12, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0.25, green: 0.54, blue: 0.92).opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 240
            )
            .offset(x: 90, y: -130)

            RadialGradient(
                colors: [Color(red: 0.37, green: 0.78, blue: 0.63).opacity(0.12), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 220
            )
            .offset(x: -80, y: 140)
        }
    }
}

struct PhoneSpotterCard<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder var content: Content

    init(padding: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(padding)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.96))
                )
        )
    }
}

struct PhoneSpotterPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [Color(red: 0.15, green: 0.47, blue: 0.92), Color(red: 0.18, green: 0.72, blue: 0.86)]
                                : [Color(red: 0.2, green: 0.56, blue: 0.98), Color(red: 0.22, green: 0.78, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundStyle(.white)
    }
}

struct PhoneSpotterSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .foregroundStyle(Color.white.opacity(0.95))
    }
}

struct PhoneSpotterStatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(tint.opacity(0.14))
                    .overlay(
                        Capsule().stroke(tint.opacity(0.24), lineWidth: 1)
                    )
            )
            .foregroundStyle(tint)
    }
}

struct PhoneSpotterMetricTile: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.42))
            } icon: {
                Image(systemName: symbolName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            Text(value)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.95))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

struct PhoneSpotterChipButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10.5, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .foregroundStyle(Color.white.opacity(0.95))
        }
        .buttonStyle(.plain)
    }
}

struct PhoneSpotterQRFrame: View {
    let image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            if let image {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white)
                    )
                    .padding(10)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(width: 150, height: 150)
    }
}
