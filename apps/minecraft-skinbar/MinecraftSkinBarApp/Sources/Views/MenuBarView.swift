import AppKit
import SwiftUI

private enum SkinBarPalette {
    static let backgroundTop = Color(red: 0.08, green: 0.09, blue: 0.11)
    static let backgroundBottom = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let panel = Color(red: 0.12, green: 0.13, blue: 0.16).opacity(0.98)
    static let raised = Color(red: 0.16, green: 0.17, blue: 0.20).opacity(0.98)
    static let border = Color.white.opacity(0.08)
    static let primaryText = Color.white.opacity(0.97)
    static let secondaryText = Color(red: 0.76, green: 0.80, blue: 0.86)
    static let mutedText = Color.white.opacity(0.58)
    static let accent = Color(red: 0.39, green: 0.87, blue: 0.52)
}

struct MenuBarView: View {
    @ObservedObject var model: SkinBarModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SkinBarPalette.backgroundTop,
                    SkinBarPalette.accent.opacity(0.10),
                    SkinBarPalette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    composeCard
                    launchRow
                    latestCard
                    actionGrid
                    footer
                }
                .padding(16)
            }
            .frame(width: 410, height: 670)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Minecraft Skin Bar")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(SkinBarPalette.primaryText)
                Text(model.headline)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(nsColor: model.phase.color))
                Text(model.subheadline)
                    .font(.caption)
                    .foregroundStyle(SkinBarPalette.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private var composeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Skin Name")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SkinBarPalette.secondaryText)
                    TextField("dracula-sun", text: $model.skinName)
                        .textFieldStyle(.plain)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SkinBarPalette.raised)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Player Model")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SkinBarPalette.secondaryText)
                    Picker("Player Model", selection: $model.isSlimModel) {
                        Text("Wide").tag(false)
                        Text("Slim").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 144)
                }
            }

            Text("Prompt")
                .font(.caption2.weight(.bold))
                .foregroundStyle(SkinBarPalette.secondaryText)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SkinBarPalette.raised)

                TextEditor(text: $model.prompt)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 13.5, weight: .medium, design: .default))
                    .foregroundStyle(SkinBarPalette.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(height: 102)
                    .background(Color.clear)

                if model.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Describe the outfit, palette, face, and vibe. Example: obsidian mage with a violet visor and gold trim.")
                        .font(.caption)
                        .foregroundStyle(SkinBarPalette.mutedText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                    .allowsHitTesting(false)
                }
            }

            HStack(spacing: 10) {
                statusChip(model.isSlimModel ? "Slim model" : "Wide model", tint: SkinBarPalette.accent.opacity(0.18), foreground: SkinBarPalette.accent)
                statusChip(model.apiKeyStatusText, tint: model.hasAnyAPIKey ? SkinBarPalette.accent.opacity(0.18) : Color.orange.opacity(0.18), foreground: model.hasAnyAPIKey ? SkinBarPalette.accent : .orange)
                statusChip("Saved to Minecraft Skins", tint: .white.opacity(0.08), foreground: SkinBarPalette.secondaryText)
                Spacer()
            }

            if model.isShowingAPIKeyField || !model.hasAnyAPIKey {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Key")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SkinBarPalette.secondaryText)

                    HStack(spacing: 8) {
                        SecureField("sk-...", text: $model.apiKeyDraft)
                            .textFieldStyle(.plain)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(SkinBarPalette.raised)
                            )

                        Button(model.hasStoredAPIKey ? "Update" : "Save") {
                            model.saveAPIKey()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Text("Needed for Generate. Import PNG works without AI.")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SkinBarPalette.mutedText)
                }
            }

            HStack(spacing: 10) {
                Button {
                    model.generateFromPrompt()
                } label: {
                    HStack(spacing: 8) {
                        if model.isRunning {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(model.isRunning ? "Working..." : "Generate")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canGenerate)

                Button {
                    model.importExistingSkin()
                } label: {
                    Label("Import PNG", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(model.isRunning)

                Button(model.isShowingAPIKeyField || !model.hasAnyAPIKey ? "Hide Key" : "API Key") {
                    model.toggleAPIKeyField()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SkinBarPalette.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(SkinBarPalette.border, lineWidth: 1)
                )
        )
    }

    private var launchRow: some View {
        HStack(spacing: 10) {
            quickLaunchButton("Launch Minecraft", systemName: "gamecontroller.fill") {
                model.openMinecraftLauncher()
            }
            quickLaunchButton("Open Skins Folder", systemName: "folder.fill") {
                model.openOutputFolder()
            }
        }
    }

    private var latestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Latest")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SkinBarPalette.secondaryText)
                Spacer()
                if let id = model.latestRegisteredID {
                    statusChip(id, tint: Color(nsColor: model.phase.color).opacity(0.18), foreground: Color(nsColor: model.phase.color))
                } else {
                    statusChip(model.phase.title, tint: Color(nsColor: model.phase.color).opacity(0.16), foreground: Color(nsColor: model.phase.color))
                }
            }

            HStack(alignment: .top, spacing: 14) {
                PreviewFrame(url: model.latestPreviewURL)

                VStack(alignment: .leading, spacing: 8) {
                    Text(model.currentName)
                        .font(.headline.weight(.black))
                        .foregroundStyle(SkinBarPalette.primaryText)
                        .lineLimit(1)

                    Text("Minecraft reads custom skins from the launcher after you generate or import them here.")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SkinBarPalette.mutedText)
                        .lineLimit(2)

                    if model.latestRegisteredID != nil {
                        Text("If the skin is missing, fully quit and reopen Minecraft Launcher to refresh the custom skins list.")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                            .lineLimit(3)
                    }

                    fileLine(label: "Skin", url: model.latestSkinURL)
                    fileLine(label: "Preview", url: model.latestPreviewURL)

                    if !model.latestOutputText.isEmpty {
                        Text(trimmedConsole(model.latestOutputText))
                            .font(.caption)
                            .foregroundStyle(SkinBarPalette.secondaryText)
                            .lineLimit(4)
                    } else {
                        Text("Your latest generated or imported skin will appear here.")
                            .font(.caption)
                            .foregroundStyle(SkinBarPalette.secondaryText)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SkinBarPalette.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(SkinBarPalette.border, lineWidth: 1)
                )
        )
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            actionButton("Open Skin", systemName: "tshirt", enabled: model.canUseLatestSkin) {
                model.openLatestSkin()
            }
            actionButton("Open Preview", systemName: "photo", enabled: model.canUseLatestPreview) {
                model.openLatestPreview()
            }
            actionButton("Reveal Files", systemName: "folder.fill", enabled: model.canUseLatestSkin || model.canUseLatestPreview) {
                model.revealLatestFiles()
            }
            actionButton("Launch Minecraft", systemName: "gamecontroller.fill", enabled: true) {
                model.openMinecraftLauncher()
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Generate or import, then choose the skin in Minecraft Launcher. If it does not show up, quit and reopen the launcher.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SkinBarPalette.mutedText)
                .lineLimit(2)

            Spacer()

            Button("Quit") {
                model.quit()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(SkinBarPalette.secondaryText)
        }
        .padding(.top, 2)
    }

    private func fileLine(label: String, url: URL?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(SkinBarPalette.mutedText)
            Text(url?.lastPathComponent ?? "Not ready yet")
                .font(.caption.weight(.semibold))
                .foregroundStyle(url == nil ? SkinBarPalette.mutedText : SkinBarPalette.primaryText)
                .lineLimit(1)
        }
    }

    private func statusChip(_ text: String, tint: Color, foreground: Color) -> some View {
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

    private func actionButton(_ title: String, systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemName)
                    .font(.headline)
                    .foregroundStyle(enabled ? SkinBarPalette.accent : SkinBarPalette.mutedText)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(enabled ? SkinBarPalette.primaryText : SkinBarPalette.mutedText)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SkinBarPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SkinBarPalette.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func quickLaunchButton(_ title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SkinBarPalette.accent)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SkinBarPalette.primaryText)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SkinBarPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SkinBarPalette.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func trimmedConsole(_ text: String) -> String {
        let cleaned = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter {
                !$0.isEmpty &&
                !$0.hasPrefix("OPENAI_API_KEY is set.") &&
                !$0.hasPrefix("Calling Image API")
            }

        if let firstError = cleaned.first(where: { $0.hasPrefix("Error:") }) {
            return firstError
        }

        let summary = cleaned
            .filter { !$0.hasPrefix("Traceback") && !$0.hasPrefix("File ") }
            .suffix(4)
            .joined(separator: "\n")
        return summary.isEmpty ? "Finished successfully." : summary
    }
}

private struct PreviewFrame: View {
    let url: URL?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SkinBarPalette.raised)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SkinBarPalette.border, lineWidth: 1)

            if let url, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(10)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(SkinBarPalette.mutedText)
                    Text("No Preview")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SkinBarPalette.mutedText)
                }
            }
        }
        .frame(width: 118, height: 158)
    }
}
