import AppKit
import SwiftUI

private enum XboxMenuPalette {
    static let top = Color(red: 0.05, green: 0.10, blue: 0.06)
    static let middle = Color(red: 0.08, green: 0.24, blue: 0.10)
    static let bottom = Color(red: 0.04, green: 0.07, blue: 0.06)
    static let card = Color(red: 0.08, green: 0.13, blue: 0.10).opacity(0.96)
    static let raised = Color(red: 0.12, green: 0.18, blue: 0.13).opacity(0.98)
    static let border = Color.white.opacity(0.08)
    static let primary = Color.white.opacity(0.96)
    static let secondary = Color(red: 0.82, green: 0.89, blue: 0.83)
    static let muted = Color.white.opacity(0.62)
}

struct MenuBarView: View {
    @ObservedObject var model: XboxStudioModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [XboxMenuPalette.top, XboxMenuPalette.middle, XboxMenuPalette.bottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    controllerCard
                    launchCard
                    connectivityCard
                    captureCard
                    footer
                }
                .padding(16)
            }
            .frame(width: 400, height: 620)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Xbox Studio")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(XboxMenuPalette.primary)
                Text(model.playerLabel.isEmpty ? model.controllers.summaryTitle : model.playerLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(XboxMenuPalette.secondary)
            }

            Spacer()

            Button {
                model.refresh()
            } label: {
                Image(systemName: model.isRefreshing ? "bolt.horizontal.circle.fill" : "arrow.clockwise")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(XboxMenuPalette.primary)
            }
            .buttonStyle(.borderless)
        }
    }

    private var controllerCard: some View {
        let card = model.controllers.primaryCard

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: card.symbolName)
                            .foregroundStyle(card.level.color)
                        Text(card.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(XboxMenuPalette.primary)
                    }

                    Text(card.detail)
                        .font(.caption)
                        .foregroundStyle(XboxMenuPalette.secondary)
                }

                Spacer()

                if let badge = card.badge {
                    chip(badge, tint: card.level.color.opacity(0.18), foreground: card.level.color)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(card.actions) { action in
                    controllerActionButton(action)
                }
            }

            if model.controllers.controllers.isEmpty {
                Text("No active controllers in GameController right now.")
                    .font(.caption)
                    .foregroundStyle(XboxMenuPalette.muted)
            } else {
                ForEach(Array(model.controllers.controllers.prefix(2))) { controller in
                    HStack(spacing: 10) {
                        Image(systemName: controller.isXboxFamily ? "gamecontroller.fill" : "gamecontroller")
                            .foregroundStyle(controller.isXboxFamily ? Color.green.opacity(0.95) : XboxMenuPalette.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(controller.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(XboxMenuPalette.primary)
                            Text(controller.detail)
                                .font(.caption)
                                .foregroundStyle(XboxMenuPalette.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(raisedBackground)
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var launchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Play and Official Surfaces")
                .font(.caption.weight(.bold))
                .foregroundStyle(XboxMenuPalette.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                actionButton("Cloud Gaming", systemImage: "cloud.fill") { model.openCloudGaming() }
                actionButton("Remote Play", systemImage: "play.tv.fill") { model.openRemotePlay() }
                actionButton("Xbox Account", systemImage: "person.crop.circle") { model.openAccount() }
                actionButton("Pairing Guide", systemImage: "book.closed") { model.openApplePairingGuide() }
            }
        }
    }

    private var connectivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: model.connectivity.level.symbolName)
                            .foregroundStyle(model.connectivity.level.color)
                        Text("Connectivity")
                            .font(.headline.weight(.black))
                            .foregroundStyle(XboxMenuPalette.primary)
                    }

                    Text(model.connectivity.headline)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(XboxMenuPalette.secondary)
                    Text("\(model.connectivity.detail) • \(model.connectivity.checkedAtLabel)")
                        .font(.caption2)
                        .foregroundStyle(XboxMenuPalette.muted)
                }

                Spacer()
            }

            ForEach(model.connectivity.probes) { probe in
                HStack(spacing: 12) {
                    Image(systemName: probe.status.symbolName)
                        .foregroundStyle(probe.status.color)
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(probe.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(XboxMenuPalette.primary)
                        Text("\(probe.summary) • \(probe.destination)")
                            .font(.caption)
                            .foregroundStyle(XboxMenuPalette.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(raisedBackground)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var captureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Capture Inbox")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(XboxMenuPalette.secondary)
                Spacer()
                Button("Open Folder") {
                    model.openCaptureFolder()
                }
                .buttonStyle(.borderless)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
            }

            Text("Export or download captures in official Xbox or Microsoft surfaces, then drag them into the dashboard inbox.")
                .font(.caption)
                .foregroundStyle(XboxMenuPalette.secondary)

            if let message = model.lastImportMessage {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.green.opacity(0.92))
            } else if let error = model.lastError {
                Text(error)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.orange.opacity(0.92))
            }

            if let first = model.captures.first {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(first.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(XboxMenuPalette.primary)
                        Text(first.subtitle)
                            .font(.caption)
                            .foregroundStyle(XboxMenuPalette.secondary)
                    }
                    Spacer()
                    Button("Reveal") {
                        model.revealCapture(first)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(raisedBackground)
            } else {
                Text("No captures in the inbox yet.")
                    .font(.caption)
                    .foregroundStyle(XboxMenuPalette.muted)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Dashboard") {
                model.openDashboard()
            }
            .buttonStyle(.borderedProminent)

            Button("Support") {
                model.openSupport()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(XboxMenuPalette.secondary)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(XboxMenuPalette.secondary)
        }
    }

    private func chip(_ text: String, tint: Color, foreground: Color = .white) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint)
            )
    }

    private func controllerActionButton(_ action: XboxControllerAction) -> some View {
        Button {
            model.performControllerAction(action)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: action.systemImage)
                Text(action.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(action.isPrimary ? Color.green.opacity(0.42) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(XboxMenuPalette.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(XboxMenuPalette.primary)
                    .multilineTextAlignment(.leading)
                Text("Open official surface")
                    .font(.caption)
                    .foregroundStyle(XboxMenuPalette.muted)
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .padding(12)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(XboxMenuPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(XboxMenuPalette.border, lineWidth: 1)
            )
    }

    private var raisedBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(XboxMenuPalette.raised)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(XboxMenuPalette.border, lineWidth: 1)
            )
    }
}
