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

struct ContextAssemblyCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? ClipboardStudioPalette.accent.opacity(0.24) : Color.white.opacity(0.07))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                configuration.isPressed ? ClipboardStudioPalette.accent.opacity(0.55) : ClipboardStudioPalette.border,
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ContextAssemblyIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.white.opacity(0.14) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct MenuBarView: View {
    @ObservedObject var model: ClipboardStudioModel
    @State private var isGuidePresented = false

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
                VStack(alignment: .leading, spacing: 12) {
                    header
                    currentFocusCard
                    actionCard
                    packCard
                    historyCard
                    footer
                }
                .padding(14)
            }
            .frame(width: 448, height: 700)
            .onAppear {
                model.refreshCurrentFocusSilently()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(ContextAssemblyBrand.appName)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(ClipboardStudioPalette.primaryText)

                        Button {
                            isGuidePresented.toggle()
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ClipboardStudioPalette.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $isGuidePresented, arrowEdge: .top) {
                            ContextAssemblyGuideCard(markdownExportFolderName: model.markdownExportFolderName)
                        }
                    }
                    Text(model.headline)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(nsColor: model.statusTone.color))
                    Text(model.subheadline)
                        .font(.caption)
                        .foregroundStyle(ClipboardStudioPalette.secondaryText)
                        .lineLimit(2)
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
                    model.isPrivateMode ? "Private Mode" : "History Live",
                    tint: model.isPrivateMode ? Color.white.opacity(0.10) : ClipboardStudioPalette.accentSoft.opacity(0.16),
                    foreground: model.isPrivateMode ? ClipboardStudioPalette.secondaryText : ClipboardStudioPalette.accentSoft
                )
                statusChip(
                    model.keepsAssemblyWindowVisible ? "Assembly Live" : "Assembly Window",
                    tint: model.keepsAssemblyWindowVisible ? ClipboardStudioPalette.accent.opacity(0.14) : Color.white.opacity(0.08),
                    foreground: model.keepsAssemblyWindowVisible ? ClipboardStudioPalette.accent : ClipboardStudioPalette.secondaryText
                )
                Spacer()
            }

            Text("Keyboard shortcuts")
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

                actionButton(model.sendActionTitle, systemName: "arrow.right.circle.fill") {
                    model.sendCurrentPack()
                }
                .disabled(!model.hasPack)
            }

            HStack(spacing: 10) {
                actionButton(model.keepsAssemblyWindowVisible ? "Open Live Assembly" : "Open Assembly", systemName: "square.stack.3d.up.fill") {
                    model.openPackEditor()
                }

                actionButton("Add Last Clip", systemName: "plus.rectangle.on.rectangle") {
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
                    model.refreshCurrentFocusManually()
                } label: {
                    Label("Refresh State", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(panelBackground)
    }

    private var currentFocusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Focus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                Spacer()
                statusChip(
                    model.currentFocusSnapshot?.statusLabel ?? "Waiting",
                    tint: (model.currentFocusSnapshot?.hasSelectedText ?? false)
                        ? ClipboardStudioPalette.accent.opacity(0.18)
                        : Color.white.opacity(0.08),
                    foreground: (model.currentFocusSnapshot?.hasSelectedText ?? false)
                        ? ClipboardStudioPalette.accent
                        : ClipboardStudioPalette.secondaryText
                )
            }

            if let snapshot = model.currentFocusSnapshot {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        statusChip(
                            "From \(snapshot.sourceLabel)",
                            tint: ClipboardStudioPalette.accent.opacity(0.16),
                            foreground: ClipboardStudioPalette.accent
                        )

                        if let detailLine = snapshot.prettyURL {
                            statusChip(
                                detailLine,
                                tint: .white.opacity(0.08),
                                foreground: ClipboardStudioPalette.secondaryText
                            )
                        }

                        Spacer()

                        Text(relativeDate(snapshot.capturedAt))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(ClipboardStudioPalette.mutedText)
                    }

                    Text(snapshot.primaryTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ClipboardStudioPalette.primaryText)
                        .lineLimit(2)

                    if let detailLine = snapshot.detailLine, detailLine != snapshot.prettyURL {
                        Text(detailLine)
                            .font(.caption)
                            .foregroundStyle(ClipboardStudioPalette.secondaryText)
                            .lineLimit(2)
                    }

                    if let selectionPreview = snapshot.selectionPreview {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Selected Right Now")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(ClipboardStudioPalette.primaryText)
                                Spacer()
                                statusChip(
                                    "Live",
                                    tint: ClipboardStudioPalette.accent.opacity(0.16),
                                    foreground: ClipboardStudioPalette.accent
                                )
                            }

                            Text(selectionPreview)
                                .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                                .foregroundStyle(ClipboardStudioPalette.primaryText)
                                .lineLimit(5)

                            HStack(spacing: 8) {
                                tinyButton("Use Selection", systemName: "plus.rectangle.on.rectangle") {
                                    model.addCurrentSelectionToPack()
                                }

                                tinyButton("Merge Selection", systemName: "arrow.triangle.merge") {
                                    model.mergeCurrentSelectionWithLatestItem()
                                }
                            }

                            HStack(spacing: 8) {
                                tinyButton("Save Selection", systemName: "square.stack.3d.down.forward") {
                                    model.saveCurrentSelectionToHistory()
                                }

                                tinyButton("Copy Selection", systemName: "doc.on.doc") {
                                    model.copyCurrentSelection()
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(ClipboardStudioPalette.raised)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(ClipboardStudioPalette.accent.opacity(0.24), lineWidth: 1)
                                )
                        )
                    }

                    HStack(spacing: 8) {
                        tinyButton("Use State", systemName: "plus.rectangle.on.rectangle") {
                            model.addCurrentFocusToPack()
                        }

                        tinyButton("Merge State", systemName: "arrow.triangle.merge") {
                            model.mergeCurrentFocusWithLatestItem()
                        }

                        tinyButton(snapshot.resumeLabel, systemName: "arrow.clockwise.circle") {
                            model.resumeCurrentFocus()
                        }
                    }

                    HStack(spacing: 8) {
                        tinyButton("Copy State", systemName: "doc.on.doc") {
                            model.copyCurrentFocus()
                        }

                        tinyButton("Refresh", systemName: "arrow.clockwise") {
                            model.refreshCurrentFocusManually()
                        }

                        tinyButton(model.isResearching ? "Thinking..." : "Research", systemName: "sparkle.magnifyingglass") {
                            model.researchCurrentFocus()
                        }
                    }
                }
            } else {
                Text("Bring a browser, IDE, terminal, or document to the front. Context Assembly will keep the latest page, selection, or window state here so it can be reused later.")
                    .font(.caption)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)

                HStack(spacing: 8) {
                    tinyButton("Refresh", systemName: "arrow.clockwise") {
                        model.refreshCurrentFocusManually()
                    }

                    tinyButton("Open Assembly", systemName: "square.stack.3d.up.fill") {
                        model.openPackEditor()
                    }
                }
            }
        }
        .padding(14)
        .background(panelBackground)
    }

    private var packCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Context Assembly")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                Spacer()
                statusChip(
                    model.contextPack.isEmpty ? "Assembly Empty" : "\(model.contextPack.count) Step\(model.contextPack.count == 1 ? "" : "s")",
                    tint: model.contextPack.isEmpty ? Color.white.opacity(0.08) : ClipboardStudioPalette.accent.opacity(0.18),
                    foreground: model.contextPack.isEmpty ? ClipboardStudioPalette.secondaryText : ClipboardStudioPalette.accent
                )
                if model.contextPack.count >= 2 {
                    Button("Merge Top 2") {
                        model.mergeLatestAssemblySteps()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                }
                if !model.contextPack.isEmpty {
                    Button("Clear") {
                        model.clearPack()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                }
            }

            TextField("What do you want help with?", text: $model.packObjective)
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
                Text("Capture code, errors, or notes with \(ClipboardStudioShortcut.captureSelection.keyChord). Each capture lands here.")
                    .font(.caption)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Capture Timeline")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ClipboardStudioPalette.secondaryText)

                    let timelineItems = Array(model.assemblyTimelineItems.enumerated())
                    ForEach(timelineItems, id: \.element.id) { index, item in
                        timelineRow(
                            item,
                            step: index + 1,
                            showsConnector: index < timelineItems.count - 1
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Preview")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(ClipboardStudioPalette.raised)

                    ScrollView(showsIndicators: false) {
                        Text(model.formattedPackPreview.isEmpty ? "Your structured assembly appears here." : model.formattedPackPreview)
                            .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(model.formattedPackPreview.isEmpty ? ClipboardStudioPalette.mutedText : ClipboardStudioPalette.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .frame(height: 168)
                }
            }

            HStack(spacing: 10) {
                Button {
                    model.sendCurrentPack()
                } label: {
                    Label(model.sendActionTitle, systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.contextPack.isEmpty)

                Button {
                    model.copyCurrentPackToClipboard()
                } label: {
                    Label("Copy Assembly", systemImage: "doc.on.doc.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(model.contextPack.isEmpty)

                Menu {
                    Button("Export To Notes") {
                        model.exportAssemblyToNotes()
                    }

                    Button(model.markdownExportActionTitle) {
                        model.exportAssemblyMarkdown()
                    }

                    Divider()

                    Button(model.markdownExportFolderName == nil ? "Choose Markdown Folder..." : "Choose Different Folder...") {
                        model.chooseMarkdownExportFolder()
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .menuStyle(.borderedButton)
                .disabled(model.contextPack.isEmpty)
            }

            if let markdownExportFolderName = model.markdownExportFolderName {
                Text("Markdown exports go straight to \(markdownExportFolderName).")
                    .font(.caption2)
                    .foregroundStyle(ClipboardStudioPalette.mutedText)
            }
        }
        .padding(14)
        .background(panelBackground)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History & States")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                Spacer()
                if !model.recentFocusStates.isEmpty {
                    Button("Clear States") {
                        model.clearFocusHistory()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                }
                Button("Clear Clips") {
                    model.clearHistory()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
            }

            TextField("Search history", text: $model.searchText)
                .textFieldStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ClipboardStudioPalette.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ClipboardStudioPalette.raised)
                )

            if !model.recentFocusStates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Recent States")
                    ForEach(model.recentFocusStates.prefix(4)) { snapshot in
                        focusStateRow(snapshot)
                    }
                }
            }

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
                    Text("Clips show up here automatically while history is live. Add any item to the assembly with one click.")
                        .font(.caption)
                        .foregroundStyle(ClipboardStudioPalette.secondaryText)
                } else {
                    ForEach(model.recentEntries.prefix(12)) { entry in
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
            Text("Accessibility enables direct capture and send. Without it, Context Assembly still assembles everything and falls back to clipboard copy.")
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

    private func timelineRow(_ item: PackItem, step: Int, showsConnector: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(ClipboardStudioPalette.accent.opacity(0.18))
                        .frame(width: 26, height: 26)

                    Text("\(step)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(ClipboardStudioPalette.accent)
                }

                if showsConnector {
                    Capsule(style: .continuous)
                        .fill(ClipboardStudioPalette.border)
                        .frame(width: 2, height: 34)
                        .padding(.top, 4)
                }
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    statusChip(
                        "From \(item.sourceLabel)",
                        tint: ClipboardStudioPalette.accent.opacity(0.16),
                        foreground: ClipboardStudioPalette.accent
                    )

                    Text(shortTime(item.capturedAt))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(ClipboardStudioPalette.mutedText)
                }

                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.primaryText)
                    .lineLimit(2)

                Text(item.text)
                    .font(.caption)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            Button {
                model.removePackItem(item)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(ClipboardStudioPalette.mutedText)
            }
            .buttonStyle(ContextAssemblyIconButtonStyle())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ClipboardStudioPalette.raised)
        )
    }

    private func focusStateRow(_ snapshot: FocusSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.primaryTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ClipboardStudioPalette.primaryText)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        statusChip(
                            "From \(snapshot.sourceLabel)",
                            tint: ClipboardStudioPalette.accent.opacity(0.14),
                            foreground: ClipboardStudioPalette.accent
                        )

                        Text(relativeDate(snapshot.capturedAt))
                            .font(.caption2)
                            .foregroundStyle(ClipboardStudioPalette.mutedText)
                    }
                }

                Spacer()
            }

            if let detailLine = snapshot.detailLine, detailLine != snapshot.prettyURL {
                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                    .lineLimit(2)
            }

            if let selectionPreview = snapshot.selectionPreview {
                Text(selectionPreview)
                    .font(.caption)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                    .lineLimit(3)
            }

            HStack(spacing: 8) {
                tinyButton("Use", systemName: "plus.rectangle.on.rectangle") {
                    model.useFocusSnapshot(snapshot)
                }

                tinyButton("Copy", systemName: "doc.on.doc") {
                    model.copyFocusSnapshot(snapshot)
                }

                tinyButton(snapshot.resumeLabel, systemName: "arrow.clockwise.circle") {
                    model.resumeFocusSnapshot(snapshot)
                }
            }
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
                        statusChip(
                            "From \(entry.sourceLabel)",
                            tint: .white.opacity(0.08),
                            foreground: ClipboardStudioPalette.secondaryText
                        )

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
                tinyButton("Add", systemName: "plus.rectangle.on.rectangle") {
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
        }
        .buttonStyle(ContextAssemblyCapsuleButtonStyle())
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

    private func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

private struct ContextAssemblyGuideCard: View {
    let markdownExportFolderName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.headline.weight(.bold))

            Text("Keep the live page, window, or selection at the top, build a short timeline under it, then paste or export one clean assembly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                guideLine("1. \(ClipboardStudioShortcut.captureSelection.keyChord) captures the current selection and starts the assembly if it is empty.")
                guideLine("2. The Current Focus card keeps the latest app/page state so you can use, copy, merge, or resume it later.")
                guideLine("3. Each capture becomes a timeline step labeled by source app, so context switches still make sense later.")
                guideLine("4. \(ClipboardStudioShortcut.sendPack.keyChord) pastes the assembled context into your target app. Export sends the same structure to Notes or Markdown.")
            }

            Text("Instead of Cmd+C, switch, Cmd+V loops, you get one structured prompt with timeline, app labels, and resumable states.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(markdownExportFolderName == nil ? "Export sends to Notes or asks for a Markdown folder once, then remembers it." : "Notes creates a new note. Markdown saves straight to \(markdownExportFolderName!).")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 304)
    }

    private func guideLine(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
