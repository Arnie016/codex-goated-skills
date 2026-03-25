import AppKit
import SwiftUI

enum ClipboardStudioPalette {
    static let backgroundTop = Color(red: 0.05, green: 0.08, blue: 0.10)
    static let backgroundBottom = Color(red: 0.03, green: 0.05, blue: 0.07)
    static let panel = Color(red: 0.10, green: 0.14, blue: 0.16).opacity(0.98)
    static let raised = Color(red: 0.14, green: 0.18, blue: 0.21).opacity(0.98)
    static let border = Color.white.opacity(0.08)
    static let primaryText = Color.white.opacity(0.97)
    static let secondaryText = Color(red: 0.76, green: 0.84, blue: 0.86)
    static let mutedText = Color.white.opacity(0.58)
    static let accent = Color(red: 0.31, green: 0.86, blue: 0.55)
    static let accentSoft = Color(red: 0.26, green: 0.72, blue: 0.50)
    static let warm = Color(red: 0.97, green: 0.73, blue: 0.35)
    static let alert = Color(red: 0.98, green: 0.52, blue: 0.43)
}

struct MenuBarView: View {
    @ObservedObject var model: ClipboardStudioModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ClipboardStudioPalette.backgroundTop,
                    ClipboardStudioPalette.accent.opacity(0.14),
                    ClipboardStudioPalette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    actionCard
                    packCard
                    historyCard
                    footer
                }
                .padding(16)
            }
            .frame(width: 456, height: 736)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clipboard Studio")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(ClipboardStudioPalette.primaryText)
                    Text(model.headline)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(nsColor: model.statusTone.color))
                    Text(model.subheadline)
                        .font(.caption)
                        .foregroundStyle(ClipboardStudioPalette.secondaryText)
                        .lineLimit(3)
                }

                Spacer()

                if let lastSendResult = model.lastSendResult {
                    sendStateChip(lastSendResult)
                }
            }
        }
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                statusChip(
                    model.accessibilityTrusted ? "Accessibility Ready" : "Enable Accessibility",
                    tint: model.accessibilityTrusted ? ClipboardStudioPalette.accent.opacity(0.18) : ClipboardStudioPalette.warm.opacity(0.18),
                    foreground: model.accessibilityTrusted ? ClipboardStudioPalette.accent : ClipboardStudioPalette.warm
                )
                statusChip(
                    "Target: \(model.targetAppLabel)",
                    tint: .white.opacity(0.08),
                    foreground: ClipboardStudioPalette.secondaryText
                )
                statusChip(
                    model.isPrivateMode ? "Private Mode" : "Clipboard Live",
                    tint: model.isPrivateMode ? Color.white.opacity(0.10) : ClipboardStudioPalette.accentSoft.opacity(0.16),
                    foreground: model.isPrivateMode ? ClipboardStudioPalette.secondaryText : ClipboardStudioPalette.accentSoft
                )
                Spacer()
            }

            Text("Keyboard-first shortcuts")
                .font(.caption.weight(.bold))
                .foregroundStyle(ClipboardStudioPalette.secondaryText)

            HStack(spacing: 8) {
                ForEach(ClipboardStudioShortcut.allCases, id: \.self) { shortcut in
                    shortcutChip(shortcut)
                }
            }

            HStack(spacing: 10) {
                actionButton("Capture Selection", systemName: "text.cursor") {
                    model.captureSelectionIntoPack()
                }

                actionButton("Send Pack", systemName: "arrow.right.circle.fill") {
                    model.sendCurrentPack()
                }
                .disabled(!model.hasPack)
            }

            HStack(spacing: 10) {
                actionButton("Open Pack", systemName: "square.stack.3d.up.fill") {
                    model.openPackEditor()
                }

                actionButton("Add Latest Clip", systemName: "plus.rectangle.on.rectangle") {
                    model.addLatestClipToPack()
                }
                .disabled(model.recentEntries.isEmpty && model.pinnedEntries.isEmpty)
            }

            HStack(spacing: 10) {
                Button {
                    model.isPrivateMode.toggle()
                } label: {
                    Label(model.isPrivateMode ? "Resume History" : "Pause History", systemImage: model.isPrivateMode ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    model.promptForAccessibilityAccess()
                } label: {
                    Label("Permissions", systemImage: "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    model.captureSelectionToHistory()
                } label: {
                    Label("Grab To History", systemImage: "square.stack.3d.down.forward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(panelBackground)
    }

    private var packCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Instant Context Pack")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                Spacer()
                statusChip(
                    model.contextPack.isEmpty ? "Pack Empty" : "\(model.contextPack.count) Ready",
                    tint: model.contextPack.isEmpty ? Color.white.opacity(0.08) : ClipboardStudioPalette.accent.opacity(0.18),
                    foreground: model.contextPack.isEmpty ? ClipboardStudioPalette.secondaryText : ClipboardStudioPalette.accent
                )
            }

            TextField("What do you want the AI to help with?", text: $model.packObjective)
                .textFieldStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ClipboardStudioPalette.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ClipboardStudioPalette.raised)
                )

            if model.contextPack.items.isEmpty {
                Text("Hit \(ClipboardStudioShortcut.captureSelection.keyChord) while highlighting code, logs, or notes. Each explicit capture lands here as a prompt section without interrupting your flow.")
                    .font(.caption)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
            } else {
                VStack(spacing: 8) {
                    ForEach(model.contextPack.items) { item in
                        packRow(item)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Prompt Preview")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(ClipboardStudioPalette.raised)

                    ScrollView(showsIndicators: false) {
                        Text(model.formattedPackPreview.isEmpty ? "Your structured AI prompt pack will render here." : model.formattedPackPreview)
                            .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(model.formattedPackPreview.isEmpty ? ClipboardStudioPalette.mutedText : ClipboardStudioPalette.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .frame(height: 188)
                }
            }

            HStack(spacing: 10) {
                Button {
                    model.sendCurrentPack()
                } label: {
                    Label("Send Pack", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.contextPack.isEmpty)

                Button {
                    model.copyCurrentPackToClipboard()
                } label: {
                    Label("Copy Pack", systemImage: "doc.on.doc.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(model.contextPack.isEmpty)

                Button("Clear") {
                    model.clearPack()
                }
                .buttonStyle(.bordered)
                .disabled(model.contextPack.isEmpty)
            }
        }
        .padding(14)
        .background(panelBackground)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                Spacer()
                Button("Clear All") {
                    model.clearHistory()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
            }

            TextField("Search clips or source apps", text: $model.searchText)
                .textFieldStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ClipboardStudioPalette.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ClipboardStudioPalette.raised)
                )

            if !model.pinnedEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Pinned")
                    ForEach(model.pinnedEntries) { entry in
                        historyRow(entry)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Recent")
                if model.recentEntries.isEmpty {
                    Text("Plain text clips show up here automatically while history is live, and you can pack any of them with one click.")
                        .font(.caption)
                        .foregroundStyle(ClipboardStudioPalette.secondaryText)
                } else {
                    ForEach(model.recentEntries.prefix(14)) { entry in
                        historyRow(entry)
                    }
                }
            }
        }
        .padding(14)
        .background(panelBackground)
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("Enable Accessibility for true one-move capture and send. Without it, Clipboard Studio still formats the pack and falls back to your clipboard.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(ClipboardStudioPalette.mutedText)
                .lineLimit(3)

            Spacer()

            Button("Quit") {
                model.quit()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(ClipboardStudioPalette.secondaryText)
        }
        .padding(.top, 2)
    }

    private func sendStateChip(_ result: LastSendResult) -> some View {
        let isFallback = result.delivery == .clipboardFallback
        return VStack(alignment: .trailing, spacing: 4) {
            Text(result.label)
                .font(.caption2.weight(.black))
                .foregroundStyle(isFallback ? ClipboardStudioPalette.warm : ClipboardStudioPalette.accent)
            Text(result.targetAppName ?? "Clipboard")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isFallback ? ClipboardStudioPalette.warm.opacity(0.16) : ClipboardStudioPalette.accent.opacity(0.16))
        )
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(ClipboardStudioPalette.mutedText)
            .textCase(.uppercase)
    }

    private func statusChip(_ text: String, tint: Color, foreground: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint)
            )
    }

    private func shortcutChip(_ shortcut: ClipboardStudioShortcut) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(shortcut.keyChord)
                .font(.caption.weight(.black))
                .foregroundStyle(ClipboardStudioPalette.primaryText)
            Text(shortcut.title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
            Text(shortcut.helpText)
                .font(.caption2)
                .foregroundStyle(ClipboardStudioPalette.mutedText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ClipboardStudioPalette.raised)
        )
    }

    private func actionButton(_ title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func packRow(_ item: PackItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ClipboardStudioPalette.primaryText)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        if let source = item.sourceAppName {
                            statusChip(
                                source,
                                tint: ClipboardStudioPalette.accent.opacity(0.16),
                                foreground: ClipboardStudioPalette.accent
                            )
                        }

                        Text(relativeDate(item.capturedAt))
                            .font(.caption2)
                            .foregroundStyle(ClipboardStudioPalette.mutedText)
                    }
                }

                Spacer()

                Button {
                    model.removePackItem(item)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ClipboardStudioPalette.mutedText)
                }
                .buttonStyle(.plain)
            }

            Text(item.text)
                .font(.caption)
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
                .lineLimit(4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ClipboardStudioPalette.raised)
        )
    }

    private func historyRow(_ entry: ClipboardEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ClipboardStudioPalette.primaryText)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        if let source = entry.sourceAppName {
                            statusChip(
                                source,
                                tint: .white.opacity(0.08),
                                foreground: ClipboardStudioPalette.secondaryText
                            )
                        }

                        Text(relativeDate(entry.createdAt))
                            .font(.caption2)
                            .foregroundStyle(ClipboardStudioPalette.mutedText)
                    }
                }

                Spacer()

                Button {
                    model.togglePin(for: entry)
                } label: {
                    Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                        .foregroundStyle(entry.isPinned ? ClipboardStudioPalette.warm : ClipboardStudioPalette.mutedText)
                }
                .buttonStyle(.plain)
            }

            Text(entry.text)
                .font(.caption)
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
                .lineLimit(4)

            HStack(spacing: 8) {
                tinyButton("Pack", systemName: "plus.rectangle.on.rectangle") {
                    model.addToPack(entry: entry)
                }

                tinyButton("Copy", systemName: "doc.on.doc") {
                    model.copyEntry(entry)
                }

                tinyButton("Paste", systemName: "arrow.right.to.line.compact") {
                    model.pasteEntry(entry)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ClipboardStudioPalette.raised)
        )
    }

    private func tinyButton(_ title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(ClipboardStudioPalette.primaryText)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(ClipboardStudioPalette.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(ClipboardStudioPalette.border, lineWidth: 1)
            )
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
