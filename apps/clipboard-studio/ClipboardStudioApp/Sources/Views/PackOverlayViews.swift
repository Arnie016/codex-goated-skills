import SwiftUI

struct CaptureToastOverlayView: View {
    @ObservedObject var model: ClipboardStudioModel

    var body: some View {
        Group {
            if let toast = model.toastState {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(toast.title)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(ClipboardStudioPalette.primaryText)
                            Text(toast.detail)
                                .font(.caption)
                                .foregroundStyle(ClipboardStudioPalette.secondaryText)
                                .lineLimit(2)
                        }

                        Spacer()

                        Text("\(toast.packCount)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(ClipboardStudioPalette.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(ClipboardStudioPalette.accent.opacity(0.16))
                            )
                    }

                    if let sourceAppName = toast.sourceAppName {
                        Text("From \(sourceAppName)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(ClipboardStudioPalette.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(ClipboardStudioPalette.accent.opacity(0.14))
                            )
                    }

                    Text(toast.preview)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ClipboardStudioPalette.primaryText)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if toast.undoItemID != nil {
                            toastAction("Undo", systemName: "arrow.uturn.backward.circle.fill") {
                                model.undoLastPackAddition()
                            }
                        }

                        toastAction("Send", systemName: "arrow.right.circle.fill") {
                            model.sendCurrentPack()
                        }

                        toastAction("Open Assembly", systemName: "square.stack.3d.up.fill") {
                            model.openPackEditor()
                        }
                    }
                }
                .padding(14)
                .frame(width: 380)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(ClipboardStudioPalette.panel.opacity(0.985))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(ClipboardStudioPalette.border, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.30), radius: 18, y: 10)
                )
                .padding(10)
                .background(Color.clear)
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
        }
    }

    private func toastAction(_ title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ContextAssemblyCapsuleButtonStyle())
        .foregroundStyle(ClipboardStudioPalette.primaryText)
    }
}

struct PackEditorOverlayView: View {
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
                VStack(alignment: .leading, spacing: 16) {
                    header
                    currentFocusCard
                    objectiveCard
                    packItemsCard
                    promptPreviewCard
                    footerActions
                }
                .padding(18)
            }
        }
        .frame(width: 540, height: 664)
        .onAppear {
            model.refreshCurrentFocusSilently()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Context Assembly")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(ClipboardStudioPalette.primaryText)
                Spacer()
                if model.keepsAssemblyWindowVisible {
                    statusChip("Stays Visible")
                }
                Button {
                    model.toggleAssemblyWindowVisibilityPin()
                } label: {
                    Image(systemName: model.keepsAssemblyWindowVisible ? "pin.fill" : "pin")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(
                            model.keepsAssemblyWindowVisible
                                ? ClipboardStudioPalette.accent
                                : ClipboardStudioPalette.secondaryText
                        )
                }
                .buttonStyle(ContextAssemblyIconButtonStyle())
                statusChip(model.contextPack.isEmpty ? "Assembly Empty" : "\(model.contextPack.count) Step\(model.contextPack.count == 1 ? "" : "s")")
            }

            Text("Capture from IDEs or browsers with \(ClipboardStudioShortcut.captureSelection.keyChord). When pinned, this window stays on screen while you highlight the next bit of context.")
                .font(.caption)
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
        }
    }

    private var objectiveCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Objective")
                .font(.caption.weight(.bold))
                .foregroundStyle(ClipboardStudioPalette.secondaryText)

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

            if let lastSendResult = model.lastSendResult {
                Text("\(lastSendResult.label) • \(lastSendResult.detail)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(lastSendResult.delivery == .directSend ? ClipboardStudioPalette.accent : ClipboardStudioPalette.warm)
            }
        }
        .padding(14)
        .background(overlayPanelBackground)
    }

    private var currentFocusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Focus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                Spacer()
                statusChip(model.currentFocusSnapshot?.statusLabel ?? "Waiting")
            }

            if let snapshot = model.currentFocusSnapshot {
                HStack(spacing: 6) {
                    statusChip("From \(snapshot.sourceLabel)")

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
                            statusChip("Live")
                        }

                        Text(selectionPreview)
                            .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(ClipboardStudioPalette.primaryText)
                            .lineLimit(5)

                        HStack(spacing: 8) {
                            overlayAction("Use Selection", systemName: "plus.rectangle.on.rectangle") {
                                model.addCurrentSelectionToPack()
                            }

                            overlayAction("Merge Selection", systemName: "arrow.triangle.merge") {
                                model.mergeCurrentSelectionWithLatestItem()
                            }
                        }

                        HStack(spacing: 8) {
                            overlayAction("Save Selection", systemName: "square.stack.3d.down.forward") {
                                model.saveCurrentSelectionToHistory()
                            }

                            overlayAction("Copy Selection", systemName: "doc.on.doc") {
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
                    overlayAction("Use State", systemName: "plus.rectangle.on.rectangle") {
                        model.addCurrentFocusToPack()
                    }

                    overlayAction("Merge State", systemName: "arrow.triangle.merge") {
                        model.mergeCurrentFocusWithLatestItem()
                    }

                    overlayAction(snapshot.resumeLabel, systemName: "arrow.clockwise.circle") {
                        model.resumeCurrentFocus()
                    }
                }

                HStack(spacing: 8) {
                    overlayAction("Copy State", systemName: "doc.on.doc") {
                        model.copyCurrentFocus()
                    }

                    overlayAction("Refresh", systemName: "arrow.clockwise") {
                        model.refreshCurrentFocusManually()
                    }

                    overlayAction(model.isResearching ? "Thinking..." : "Research", systemName: "sparkle.magnifyingglass") {
                        model.researchCurrentFocus()
                    }
                }
            } else {
                Text("The latest page, document, or selection will appear here so it can be reused or resumed later.")
                    .font(.caption)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)

                HStack(spacing: 8) {
                    overlayAction("Refresh", systemName: "arrow.clockwise") {
                        model.refreshCurrentFocusManually()
                    }

                    overlayAction("Capture", systemName: "text.cursor") {
                        model.captureSelectionIntoPack()
                    }
                }
            }
        }
        .padding(14)
        .background(overlayPanelBackground)
    }

    private var packItemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Capture Timeline")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                Spacer()
                if model.contextPack.count >= 2 {
                    Button("Merge Top 2") {
                        model.mergeLatestAssemblySteps()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                }
                Button("Clear") {
                    model.clearPack()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
            }

            if model.contextPack.items.isEmpty {
                Text("Use \(ClipboardStudioShortcut.captureSelection.keyChord) while highlighting code, logs, or notes. Each capture lands here.")
                    .font(.caption)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
            } else {
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
        .padding(14)
        .background(overlayPanelBackground)
    }

    private var promptPreviewCard: some View {
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
                .frame(height: 176)
            }
        }
        .padding(14)
        .background(overlayPanelBackground)
    }

    private var footerActions: some View {
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

            Button("Close") {
                model.closePackEditor()
            }
            .buttonStyle(.bordered)
        }
    }

    private func timelineRow(_ item: PackItem, step: Int, showsConnector: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(ClipboardStudioPalette.accent.opacity(0.18))
                        .frame(width: 28, height: 28)

                    Text("\(step)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(ClipboardStudioPalette.accent)
                }

                if showsConnector {
                    Capsule(style: .continuous)
                        .fill(ClipboardStudioPalette.border)
                        .frame(width: 2, height: 40)
                        .padding(.top, 4)
                }
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    statusChip("From \(item.sourceLabel)")

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

            Spacer(minLength: 8)

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

    private func overlayAction(_ title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ContextAssemblyCapsuleButtonStyle())
        .foregroundStyle(ClipboardStudioPalette.primaryText)
    }

    private func statusChip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(ClipboardStudioPalette.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(ClipboardStudioPalette.accent.opacity(0.16))
            )
    }

    private var overlayPanelBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(ClipboardStudioPalette.panel.opacity(0.985))
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
