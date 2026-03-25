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
                    statusCard
                    quickActions
                    captureCard
                    footer
                }
                .padding(16)
            }
            .frame(width: 388, height: 560)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Xbox Studio")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(XboxMenuPalette.primary)
                Text(model.playerLabel.isEmpty ? "Cloud, remote, controllers, captures" : model.playerLabel)
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

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: model.connectivity.level.symbolName)
                            .foregroundStyle(model.connectivity.level.color)
                        Text(model.connectivity.headline)
                            .font(.headline.weight(.black))
                            .foregroundStyle(XboxMenuPalette.primary)
                    }

                    Text(model.connectivity.detail)
                        .font(.caption)
                        .foregroundStyle(XboxMenuPalette.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                chip(model.controllers.bluetoothTitle, tint: model.controllers.bluetoothLevel.color.opacity(0.18), foreground: model.controllers.bluetoothLevel.color)
                chip("\(model.controllers.controllerCount) controller(s)", tint: Color.white.opacity(0.12))
                chip("\(model.captures.count) capture(s)", tint: Color.white.opacity(0.12))
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
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(XboxMenuPalette.raised)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(XboxMenuPalette.border, lineWidth: 1)
                        )
                )
            }

            Text(model.connectivity.checkedAtLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(XboxMenuPalette.muted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(XboxMenuPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(XboxMenuPalette.border, lineWidth: 1)
                )
        )
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.caption.weight(.bold))
                .foregroundStyle(XboxMenuPalette.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                actionButton("Cloud Gaming", systemImage: "cloud.fill") { model.openCloudGaming() }
                actionButton("Remote Play", systemImage: "play.tv.fill") { model.openRemotePlay() }
                actionButton("Xbox Account", systemImage: "person.crop.circle") { model.openAccount() }
                actionButton("Bluetooth", systemImage: "dot.radiowaves.left.and.right") { model.openBluetoothSettings() }
            }
        }
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

            Text("Sign in in your browser, download or export clips, then drag them into the dashboard inbox.")
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
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(XboxMenuPalette.raised)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(XboxMenuPalette.border, lineWidth: 1)
                        )
                )
            } else {
                Text("No captures in the inbox yet.")
                    .font(.caption)
                    .foregroundStyle(XboxMenuPalette.muted)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(XboxMenuPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(XboxMenuPalette.border, lineWidth: 1)
                )
        )
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
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(XboxMenuPalette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(XboxMenuPalette.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
