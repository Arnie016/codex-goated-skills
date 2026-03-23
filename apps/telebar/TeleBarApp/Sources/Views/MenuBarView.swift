import AppKit
import SwiftUI

private enum TeleBarPalette {
    static let backgroundTop = Color(red: 0.075, green: 0.085, blue: 0.105)
    static let backgroundBottom = Color(red: 0.055, green: 0.060, blue: 0.075)
    static let surface = Color(red: 0.105, green: 0.115, blue: 0.140).opacity(0.98)
    static let raised = Color(red: 0.135, green: 0.145, blue: 0.175).opacity(0.98)
    static let selected = Color(red: 0.095, green: 0.190, blue: 0.305).opacity(0.82)
    static let border = Color.white.opacity(0.09)
    static let separator = Color.white.opacity(0.08)
    static let primaryText = Color.white.opacity(0.97)
    static let secondaryText = Color.white.opacity(0.78)
    static let mutedText = Color.white.opacity(0.54)
    static let accent = Color(red: 0.33, green: 0.70, blue: 1.00)
    static let accentSoft = Color(red: 0.54, green: 0.82, blue: 1.00)
}

struct MenuBarView: View {
    @ObservedObject var model: TeleBarModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    TeleBarPalette.backgroundTop,
                    TeleBarPalette.accent.opacity(0.08),
                    TeleBarPalette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    overviewPanel
                    nextStepPanel
                    tabPicker
                    tabContent
                    footer
                }
                .padding(12)
            }
            .frame(width: 364, height: 534)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TeleBar")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(TeleBarPalette.primaryText)

                Text(model.botProfile?.displayName ?? "Telegram Control Center")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TeleBarPalette.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            statusChip(model.phase.title, tint: Color(nsColor: model.phase.color).opacity(0.18), foreground: Color(nsColor: model.phase.color))

            Button {
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(TeleBarPalette.secondaryText)
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.borderless)
            .help(startGuideText)

            Button {
                model.refreshInbox()
            } label: {
                Image(systemName: model.phase == .refreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(TeleBarPalette.primaryText)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .disabled(!model.canRefresh)
            .help("Refresh recent Telegram bot activity.")
        }
    }

    private var overviewPanel: some View {
        HStack(spacing: 8) {
            compactMetric("Chats", "\(model.threadCount)")
            compactMetric("Msgs", "\(model.messageCount)")
            compactMetric("Mode", model.hasAnyOpenAIKey ? "AI" : "Manual")

            Spacer(minLength: 0)

            capabilityChip(model.hasAnyTelegramToken ? "bot ready" : "add bot", foreground: model.hasAnyTelegramToken ? TeleBarPalette.accentSoft : .orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(groupedBackground())
    }

    @ViewBuilder
    private var nextStepPanel: some View {
        if !model.hasAnyTelegramToken {
            hintPanel(
                title: "Get started",
                body: "1. Save your Telegram bot token in Setup. 2. Refresh Chats. 3. Message the bot once in Telegram if nothing shows up yet."
            )
        } else if model.threads.isEmpty {
            hintPanel(
                title: "Next step",
                body: "Send your bot a test message in Telegram, then hit Refresh here. TeleBar only shows chats the bot is allowed to see."
            )
        } else if !model.hasAnyOpenAIKey {
            hintPanel(
                title: "Optional upgrade",
                body: "Add your OpenAI key in Setup if you want summaries and draft replies. Manual sending already works."
            )
        }
    }

    private var tabPicker: some View {
        Picker("Section", selection: $model.selectedTab) {
            ForEach(TeleBarModel.Tab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: model.selectedTab) { _, _ in
            UserDefaults.standard.set(model.selectedTab.rawValue, forKey: "teleBar.selectedTab")
        }
        .help("Chats shows recent activity, Write handles summaries and replies, Setup stores keys and Telegram shortcuts.")
    }

    @ViewBuilder
    private var tabContent: some View {
        switch model.selectedTab {
        case .inbox:
            inboxView
        case .ai:
            aiView
        case .setup:
            setupView
        }
    }

    private var inboxView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let selected = model.selectedThread {
                selectedThreadPanel(selected)
            } else {
                emptyPanel(
                    title: "No chat selected",
                    body: "Save a bot token in Setup and refresh to load recent Telegram activity."
                )
            }

            if model.threads.isEmpty {
                emptyPanel(
                    title: "No inbox activity yet",
                    body: "TeleBar only sees chats your bot is allowed to read."
                )
            } else {
                groupedPanel {
                    sectionLabel("Recent Chats", trailing: "\(model.threadCount)")

                    ForEach(Array(model.threads.prefix(6).enumerated()), id: \.element.id) { index, thread in
                        if index > 0 {
                            Divider().overlay(TeleBarPalette.separator)
                        }
                        chatRow(thread)
                    }
                }
            }
        }
    }

    private var aiView: some View {
        VStack(alignment: .leading, spacing: 10) {
            groupedPanel {
                sectionLabel("Write", trailing: model.selectedThread?.title ?? "pick a chat")

                Picker("Tone", selection: $model.selectedTone) {
                    ForEach(TeleBarModel.ReplyTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: model.selectedTone) { _, _ in
                    UserDefaults.standard.set(model.selectedTone.rawValue, forKey: "teleBar.replyTone")
                }

                HStack(spacing: 8) {
                    Button("Summarize") {
                        model.summarizeSelectedThread()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canUseAI)
                    .help("Turn the selected chat into a short, useful recap.")

                    Button("Draft Reply") {
                        model.draftReply()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!model.canUseAI)
                    .help("Create a ready-to-send reply using the selected tone.")
                }

                compactEditor(
                    text: $model.instructionDraft,
                    height: 58,
                    placeholder: "Optional steering for tone, summary style, or reply style."
                )
                .onChange(of: model.instructionDraft) { _, _ in
                    UserDefaults.standard.set(model.instructionDraft, forKey: "teleBar.instructionDraft")
                }
                .help("Optional instructions for the AI. Example: keep it concise, founder-like, or support-first.")
            }

            groupedPanel {
                sectionLabel("Summary", trailing: model.summaryText.isEmpty ? "empty" : "ready")
                compactReadOnly(model.summaryText.isEmpty ? "A compact summary of the selected chat will appear here." : model.summaryText)
                HStack {
                    Spacer()
                    Button("Copy Summary") {
                        model.copySummary()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.summaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Copy the summary to your clipboard.")
                }
            }

            groupedPanel {
                sectionLabel("Reply", trailing: model.canSend ? "sendable" : "draft")
                compactEditor(
                    text: $model.composeText,
                    height: 92,
                    placeholder: "Draft a Telegram reply here or write your own."
                )
                .onChange(of: model.composeText) { _, _ in
                    UserDefaults.standard.set(model.composeText, forKey: "teleBar.composeText")
                }

                HStack(spacing: 8) {
                    Button("Copy") {
                        model.copyCompose()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Copy the drafted reply.")

                    Button("Clear") {
                        model.clearCompose()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Clear the current reply draft.")

                    Spacer()

                    Button("Send") {
                        model.sendReply()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canSend)
                    .help("Send the reply through your Telegram bot.")
                }
            }
        }
    }

    private var setupView: some View {
        VStack(alignment: .leading, spacing: 10) {
            groupedPanel {
                sectionLabel("Keys", trailing: "stored locally")

                labeledSecureField(
                    title: "Telegram Bot Token",
                    text: $model.telegramTokenDraft,
                    placeholder: "123456:AA..."
                ) {
                    Button(model.hasStoredTelegramToken ? "Update" : "Save") {
                        model.saveTelegramToken()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.telegramTokenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Save or update the Telegram bot token from BotFather.")
                }

                Divider().overlay(TeleBarPalette.separator)

                labeledSecureField(
                    title: "OpenAI API Key",
                    text: $model.openAIKeyDraft,
                    placeholder: "sk-..."
                ) {
                    Button(model.hasStoredOpenAIKey ? "Update" : "Save") {
                        model.saveOpenAIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.openAIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Save or update the OpenAI key used for summaries and reply drafts.")
                }
            }

            groupedPanel {
                sectionLabel("Telegram Shortcuts", trailing: model.botProfile?.displayName ?? "BotFather")

                shortcutRow("Open BotFather", systemName: "person.crop.circle.badge.plus") {
                    model.openBotFather()
                }
                Divider().overlay(TeleBarPalette.separator)
                shortcutRow("Create New Bot", systemName: "plus.bubble.fill") {
                    model.startNewBotFlow()
                }
                Divider().overlay(TeleBarPalette.separator)
                shortcutRow("Enable Inline @ Mode", systemName: "at.circle.fill") {
                    model.startInlineSetupFlow()
                }
                Divider().overlay(TeleBarPalette.separator)
                shortcutRow("Open Bot Chat", systemName: "paperplane.fill") {
                    model.openBotChat()
                }
                Divider().overlay(TeleBarPalette.separator)
                shortcutRow("Add Bot To Group", systemName: "person.3.fill") {
                    model.openAddToGroup()
                }
                Divider().overlay(TeleBarPalette.separator)
                shortcutRow("Add Bot To Channel", systemName: "megaphone.fill") {
                    model.openAddToChannel()
                }
                Divider().overlay(TeleBarPalette.separator)
                shortcutRow("Open Attach Menu Flow", systemName: "square.and.arrow.up.fill") {
                    model.openAttachFlow()
                }
                Divider().overlay(TeleBarPalette.separator)
                shortcutRow("Copy @ Handle", systemName: "doc.on.doc.fill") {
                    model.copyMentionHandle()
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button("Refresh") {
                model.refreshInbox()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canRefresh)

            Button("Quit") {
                model.quit()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(TeleBarPalette.secondaryText)

            Spacer()
        }
        .padding(.top, 2)
    }

    private func selectedThreadPanel(_ thread: TelegramThread) -> some View {
        groupedPanel {
            sectionLabel("Selected Chat", trailing: thread.kind.title)

            Text(thread.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(TeleBarPalette.primaryText)
                .lineLimit(1)

            Text(thread.latestText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TeleBarPalette.secondaryText)
                .lineLimit(3)

            HStack(spacing: 8) {
                capabilityChip(relativeDate(thread.latestDate), foreground: TeleBarPalette.secondaryText)
                capabilityChip("\(thread.recentCount) recent", foreground: TeleBarPalette.accentSoft)
                if let username = thread.username, !username.isEmpty {
                    capabilityChip("@\(username)", foreground: TeleBarPalette.secondaryText)
                }
            }

            HStack(spacing: 8) {
                Button("Summarize") {
                    model.summarizeSelectedThread()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canUseAI)
                .help("Summarize the selected chat.")

                Button("Draft Reply") {
                    model.draftReply()
                }
                .buttonStyle(.bordered)
                .disabled(!model.canUseAI)
                .help("Draft a reply for the selected chat.")
            }
        }
        .help("The selected chat is your current working thread.")
    }

    private func chatRow(_ thread: TelegramThread) -> some View {
        Button {
            model.selectThread(thread)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(thread.id == model.selectedThread?.id ? TeleBarPalette.selected : TeleBarPalette.raised)
                        .frame(width: 34, height: 34)

                    Image(systemName: thread.kind.symbolName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TeleBarPalette.primaryText)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(thread.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TeleBarPalette.primaryText)
                        .lineLimit(1)

                    Text(thread.latestText)
                        .font(.caption)
                        .foregroundStyle(TeleBarPalette.secondaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(thread.recentCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TeleBarPalette.primaryText)
                    Text(relativeDate(thread.latestDate))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(TeleBarPalette.mutedText)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .help("Select this chat to summarize it, draft a reply, or send a message.")
    }

    private func shortcutRow(_ title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TeleBarPalette.accentSoft)
                    .frame(width: 18)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TeleBarPalette.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TeleBarPalette.mutedText)
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .help(shortcutHelpText(for: title))
    }

    private func labeledSecureField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        trailing: () -> some View
    ) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TeleBarPalette.secondaryText)

                SecureField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TeleBarPalette.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(TeleBarPalette.raised)
                    )
                    .help(title == "Telegram Bot Token" ? "Paste the bot token you got from BotFather." : "Paste the OpenAI API key used for summaries and drafts.")
            }

            trailing()
        }
    }

    private func groupedPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(groupedBackground())
    }

    private func groupedBackground() -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(TeleBarPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TeleBarPalette.border, lineWidth: 1)
            )
    }

    private func compactMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(TeleBarPalette.mutedText)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(TeleBarPalette.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(TeleBarPalette.raised)
        )
    }

    private func capabilityChip(_ text: String, foreground: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.08))
            )
    }

    private func statusChip(_ text: String, tint: Color, foreground: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundStyle(foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(tint)
            )
    }

    private func sectionLabel(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(TeleBarPalette.secondaryText)
            Spacer()
            Text(trailing)
                .font(.caption2.weight(.bold))
                .foregroundStyle(TeleBarPalette.mutedText)
                .lineLimit(1)
        }
    }

    private func emptyPanel(title: String, body: String) -> some View {
        groupedPanel {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TeleBarPalette.primaryText)
            Text(body)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TeleBarPalette.secondaryText)
        }
    }

    private func hintPanel(title: String, body: String) -> some View {
        groupedPanel {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TeleBarPalette.accentSoft)
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TeleBarPalette.secondaryText)
            }

            Text(body)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TeleBarPalette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .help(startGuideText)
    }

    private func compactReadOnly(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(TeleBarPalette.primaryText)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TeleBarPalette.raised)
            )
    }

    private func compactEditor(text: Binding<String>, height: CGFloat, placeholder: String) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TeleBarPalette.raised)

            TextEditor(text: text)
                .scrollContentBackground(.hidden)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(TeleBarPalette.primaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .frame(height: height)
                .background(Color.clear)

            if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(.caption)
                    .foregroundStyle(TeleBarPalette.mutedText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .allowsHitTesting(false)
            }
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var startGuideText: String {
        """
        Quick start:
        1. Open Setup and save your Telegram bot token.
        2. Refresh Chats to load recent bot-visible activity.
        3. Pick a chat.
        4. Use Write to summarize or draft.
        5. Send through Telegram when ready.
        """
    }

    private func shortcutHelpText(for title: String) -> String {
        switch title {
        case "Open BotFather":
            return "Open Telegram's official bot management chat."
        case "Create New Bot":
            return "Copy /newbot and open BotFather so you can create a new Telegram bot fast."
        case "Enable Inline @ Mode":
            return "Copy /setinline and open BotFather to enable @yourbot usage inside chats."
        case "Open Bot Chat":
            return "Open the bot's public Telegram chat."
        case "Add Bot To Group":
            return "Open a Telegram flow that adds your bot to a group with suggested admin rights."
        case "Add Bot To Channel":
            return "Open a Telegram flow that adds your bot to a channel with suggested posting rights."
        case "Open Attach Menu Flow":
            return "Open Telegram's attach menu setup flow for richer sharing surfaces."
        case "Copy @ Handle":
            return "Copy the bot's @handle so you can paste it into Telegram quickly."
        default:
            return title
        }
    }
}
