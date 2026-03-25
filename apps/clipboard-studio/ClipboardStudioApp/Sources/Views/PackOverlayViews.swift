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
                        Text(sourceAppName)
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

                        toastAction("Open Pack", systemName: "square.stack.3d.up.fill") {
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
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
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
                    objectiveCard
                    packItemsCard
                    promptPreviewCard
                    footerActions
                }
                .padding(18)
            }
        }
        .frame(width: 560, height: 700)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Instant Context Pack")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(ClipboardStudioPalette.primaryText)
                Spacer()
                statusChip(model.contextPack.isEmpty ? "Pack Empty" : "\(model.contextPack.count) Ready")
            }

            Text("Capture from your IDEs and browsers with \(ClipboardStudioShortcut.captureSelection.keyChord), then send the whole prompt pack with \(ClipboardStudioShortcut.sendPack.keyChord).")
                .font(.caption)
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
        }
    }

    private var objectiveCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Objective")
                .font(.caption.weight(.bold))
                .foregroundStyle(ClipboardStudioPalette.secondaryText)

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

            if let lastSendResult = model.lastSendResult {
                Text("\(lastSendResult.label) • \(lastSendResult.detail)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(lastSendResult.delivery == .directSend ? ClipboardStudioPalette.accent : ClipboardStudioPalette.warm)
            }
        }
        .padding(14)
        .background(overlayPanelBackground)
    }

    private var packItemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Captured Context")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
                Spacer()
                Button("Clear") {
                    model.clearPack()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(ClipboardStudioPalette.secondaryText)
            }

            if model.contextPack.items.isEmpty {
                Text("Use \(ClipboardStudioShortcut.captureSelection.keyChord) while highlighting code, logs, or notes. Each capture lands here without pulling you out of flow.")
                    .font(.caption)
                    .foregroundStyle(ClipboardStudioPalette.secondaryText)
            } else {
                ForEach(model.contextPack.items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(ClipboardStudioPalette.primaryText)
                                    .lineLimit(2)

                                HStack(spacing: 6) {
                                    if let sourceAppName = item.sourceAppName {
                                        statusChip(sourceAppName)
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
            }
        }
        .padding(14)
        .background(overlayPanelBackground)
    }

    private var promptPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Prompt Preview")
                .font(.caption.weight(.bold))
                .foregroundStyle(ClipboardStudioPalette.secondaryText)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ClipboardStudioPalette.raised)

                ScrollView(showsIndicators: false) {
                    Text(model.formattedPackPreview.isEmpty ? "Your formatted AI prompt pack will appear here." : model.formattedPackPreview)
                        .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(model.formattedPackPreview.isEmpty ? ClipboardStudioPalette.mutedText : ClipboardStudioPalette.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(height: 190)
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

            Button("Close") {
                model.closePackEditor()
            }
            .buttonStyle(.bordered)
        }
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
}
