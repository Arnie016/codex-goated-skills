import AppKit
import Foundation

@MainActor
final class TeleBarModel: ObservableObject {
    enum Phase {
        case idle
        case refreshing
        case summarizing
        case drafting
        case sending
        case ready
        case failure

        var title: String {
            switch self {
            case .idle: return "Ready"
            case .refreshing: return "Refreshing"
            case .summarizing: return "Summarizing"
            case .drafting: return "Drafting"
            case .sending: return "Sending"
            case .ready: return "Live"
            case .failure: return "Needs Attention"
            }
        }

        var color: NSColor {
            switch self {
            case .idle:
                return NSColor(calibratedRed: 0.61, green: 0.69, blue: 0.79, alpha: 1)
            case .refreshing, .summarizing, .drafting, .sending:
                return NSColor(calibratedRed: 0.26, green: 0.62, blue: 0.98, alpha: 1)
            case .ready:
                return NSColor(calibratedRed: 0.30, green: 0.84, blue: 0.64, alpha: 1)
            case .failure:
                return NSColor(calibratedRed: 1.00, green: 0.66, blue: 0.28, alpha: 1)
            }
        }

        var symbolName: String {
            switch self {
            case .idle, .ready: return "paperplane.circle.fill"
            case .refreshing: return "arrow.clockwise.circle.fill"
            case .summarizing, .drafting: return "sparkles"
            case .sending: return "paperplane.fill"
            case .failure: return "exclamationmark.triangle.fill"
            }
        }
    }

    enum Tab: String, CaseIterable, Identifiable {
        case inbox = "Chats"
        case ai = "Write"
        case setup = "Setup"

        var id: String { rawValue }
    }

    enum ReplyTone: String, CaseIterable, Identifiable {
        case clear = "Clear"
        case founder = "Founder"
        case witty = "Witty"
        case support = "Support"

        var id: String { rawValue }

        var summaryStyle: String {
            switch self {
            case .clear: return "neutral, crisp, operator-style"
            case .founder: return "confident, concise, strategic"
            case .witty: return "lightly clever, still clear"
            case .support: return "warm, helpful, trustworthy"
            }
        }

        var replyStyle: String {
            switch self {
            case .clear: return "calm and concise"
            case .founder: return "sharp, confident, product-minded"
            case .witty: return "smart, lightly playful, not cheesy"
            case .support: return "friendly, empathetic, reassuring"
            }
        }
    }

    private enum DefaultsKey {
        static let selectedTab = "teleBar.selectedTab"
        static let selectedChatID = "teleBar.selectedChatID"
        static let instructionDraft = "teleBar.instructionDraft"
        static let composeText = "teleBar.composeText"
        static let replyTone = "teleBar.replyTone"
    }

    private enum Secrets {
        static let service = "com.arnav.TeleBar"
        static let telegramToken = "telegram_bot_token"
        static let openAIKey = "openai_api_key"
    }

    @Published var selectedTab: Tab = .inbox
    @Published var selectedTone: ReplyTone = .support
    @Published var telegramTokenDraft: String = ""
    @Published var openAIKeyDraft: String = ""
    @Published var instructionDraft: String = ""
    @Published var composeText: String = ""
    @Published private(set) var summaryText: String = ""
    @Published private(set) var threads: [TelegramThread] = []
    @Published private(set) var botProfile: TelegramBotProfile?
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var headline: String = "Connect a bot and work Telegram from the menu bar."
    @Published private(set) var subheadline: String = "Chats, writing, and setup stay one click away."
    @Published private(set) var hasStoredTelegramToken = false
    @Published private(set) var hasStoredOpenAIKey = false
    @Published var selectedChatID: Int64?

    private let telegramService = TelegramService()
    private let openAIService = OpenAIService()
    private let defaults = UserDefaults.standard
    private let keychain = KeychainStore(service: Secrets.service)

    init() {
        if let tab = Tab(rawValue: defaults.string(forKey: DefaultsKey.selectedTab) ?? "") {
            selectedTab = tab
        }
        if let tone = ReplyTone(rawValue: defaults.string(forKey: DefaultsKey.replyTone) ?? "") {
            selectedTone = tone
        }
        instructionDraft = defaults.string(forKey: DefaultsKey.instructionDraft) ?? ""
        composeText = defaults.string(forKey: DefaultsKey.composeText) ?? ""
        let storedChatID = defaults.object(forKey: DefaultsKey.selectedChatID) as? Int64
        selectedChatID = storedChatID
        loadSecretsState()
    }

    var selectedThread: TelegramThread? {
        guard let selectedChatID else { return threads.first }
        return threads.first(where: { $0.chatID == selectedChatID }) ?? threads.first
    }

    var menuBarSymbolName: String {
        if phase == .failure {
            return "ellipsis.message.fill"
        }
        return phase.symbolName
    }

    var menuBarHelp: String {
        "\(phase.title) • \(headline)"
    }

    var threadCount: Int {
        threads.count
    }

    var messageCount: Int {
        threads.reduce(0) { $0 + $1.messages.count }
    }

    var availableTelegramToken: String? {
        if let fromEnv = ProcessInfo.processInfo.environment["TELEGRAM_BOT_TOKEN"], !fromEnv.isEmpty {
            return fromEnv
        }
        return try? keychain.read(account: Secrets.telegramToken)
    }

    var availableOpenAIKey: String? {
        if let fromEnv = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !fromEnv.isEmpty {
            return fromEnv
        }
        return try? keychain.read(account: Secrets.openAIKey)
    }

    var hasAnyTelegramToken: Bool {
        !(availableTelegramToken ?? "").isEmpty
    }

    var hasAnyOpenAIKey: Bool {
        !(availableOpenAIKey ?? "").isEmpty
    }

    var canRefresh: Bool {
        hasAnyTelegramToken && !isBusy
    }

    var canUseAI: Bool {
        selectedThread != nil && hasAnyOpenAIKey && !isBusy
    }

    var canSend: Bool {
        selectedThread != nil && hasAnyTelegramToken && !composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isBusy
    }

    var isBusy: Bool {
        switch phase {
        case .refreshing, .summarizing, .drafting, .sending:
            return true
        default:
            return false
        }
    }

    var botUsername: String? {
        botProfile?.safeUsername
    }

    func refreshInbox() {
        guard let token = availableTelegramToken, !token.isEmpty else {
            selectedTab = .setup
            fail(headline: "Add a Telegram bot token first.", subheadline: "Paste the token from BotFather in Setup, then refresh again.")
            return
        }

        phase = .refreshing
        headline = "Refreshing Telegram inbox..."
        subheadline = "Pulling recent updates from your bot."

        Task {
            do {
                let snapshot = try await telegramService.fetchInbox(botToken: token)
                botProfile = snapshot.bot
                threads = snapshot.threads
                if let selectedChatID, !threads.contains(where: { $0.chatID == selectedChatID }) {
                    self.selectedChatID = threads.first?.chatID
                } else if self.selectedChatID == nil {
                    self.selectedChatID = threads.first?.chatID
                }
                persistSelection()
                phase = .ready
                headline = snapshot.bot.displayName + " connected"
                if threads.isEmpty {
                    subheadline = "The bot is live. No recent chat activity has arrived yet."
                } else {
                    subheadline = "\(threads.count) chats ready for summary, reply, and send."
                }
            } catch {
                fail(headline: "Could not refresh Telegram.", subheadline: error.localizedDescription)
            }
        }
    }

    func summarizeSelectedThread() {
        guard let thread = selectedThread else {
            fail(headline: "Pick a chat first.", subheadline: "Select a thread in Inbox before asking for a summary.")
            return
        }
        guard let apiKey = availableOpenAIKey, !apiKey.isEmpty else {
            selectedTab = .setup
            fail(headline: "Add your OpenAI key first.", subheadline: "TeleBar uses the AI key for summaries and reply drafts.")
            return
        }

        selectedTab = .ai
        phase = .summarizing
        headline = "Summarizing \(thread.title)..."
        subheadline = "Turning the recent messages into a tight brief."

        Task {
            do {
                let result = try await openAIService.summarize(
                    thread: thread,
                    bot: botProfile,
                    tone: selectedTone,
                    instruction: instructionDraft.trimmingCharacters(in: .whitespacesAndNewlines),
                    apiKey: apiKey
                )
                summaryText = result
                phase = .ready
                headline = "Summary ready"
                subheadline = "High-signal recap for \(thread.title)."
            } catch {
                fail(headline: "Could not summarize that chat.", subheadline: error.localizedDescription)
            }
        }
    }

    func draftReply() {
        guard let thread = selectedThread else {
            fail(headline: "Pick a chat first.", subheadline: "Select a thread in Inbox before drafting a reply.")
            return
        }
        guard let apiKey = availableOpenAIKey, !apiKey.isEmpty else {
            selectedTab = .setup
            fail(headline: "Add your OpenAI key first.", subheadline: "TeleBar uses the AI key for summaries and reply drafts.")
            return
        }

        selectedTab = .ai
        phase = .drafting
        headline = "Drafting a reply..."
        subheadline = "Using the selected tone and recent chat context."

        Task {
            do {
                let result = try await openAIService.draftReply(
                    thread: thread,
                    bot: botProfile,
                    tone: selectedTone,
                    instruction: instructionDraft.trimmingCharacters(in: .whitespacesAndNewlines),
                    apiKey: apiKey
                )
                composeText = result
                persistDrafts()
                phase = .ready
                headline = "Reply ready"
                subheadline = "You can send it as-is or tweak it first."
            } catch {
                fail(headline: "Could not draft a reply.", subheadline: error.localizedDescription)
            }
        }
    }

    func sendReply() {
        guard let thread = selectedThread else {
            fail(headline: "Pick a chat first.", subheadline: "Select a thread before sending a message.")
            return
        }
        guard let token = availableTelegramToken, !token.isEmpty else {
            selectedTab = .setup
            fail(headline: "Add your Telegram bot token first.", subheadline: "TeleBar needs the bot token to send messages.")
            return
        }

        let trimmed = composeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            fail(headline: "Write a reply first.", subheadline: "Draft a reply or type your own message before sending.")
            return
        }

        phase = .sending
        headline = "Sending to \(thread.title)..."
        subheadline = "Posting through the Telegram Bot API."

        Task {
            do {
                try await telegramService.sendMessage(botToken: token, chatID: thread.chatID, text: trimmed)
                applySentMessage(text: trimmed, in: thread)
                phase = .ready
                headline = "Message sent"
                subheadline = "Telegram accepted the reply."
            } catch {
                fail(headline: "Could not send that reply.", subheadline: error.localizedDescription)
            }
        }
    }

    func saveTelegramToken() {
        let trimmed = telegramTokenDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try keychain.write(trimmed, account: Secrets.telegramToken)
            telegramTokenDraft = ""
            hasStoredTelegramToken = true
            headline = "Telegram token saved"
            subheadline = "Refresh Inbox to fetch your bot activity."
        } catch {
            fail(headline: "Could not save the bot token.", subheadline: error.localizedDescription)
        }
    }

    func saveOpenAIKey() {
        let trimmed = openAIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try keychain.write(trimmed, account: Secrets.openAIKey)
            openAIKeyDraft = ""
            hasStoredOpenAIKey = true
            headline = "OpenAI key saved"
            subheadline = "Summaries and reply drafting are ready."
        } catch {
            fail(headline: "Could not save the AI key.", subheadline: error.localizedDescription)
        }
    }

    func selectThread(_ thread: TelegramThread) {
        selectedChatID = thread.chatID
        persistSelection()
    }

    func applyPromptDeck(_ value: String) {
        instructionDraft = value
        persistDrafts()
    }

    func clearCompose() {
        composeText = ""
        persistDrafts()
    }

    func copyCompose() {
        copyToPasteboard(composeText)
        headline = "Reply copied"
        subheadline = "Paste it anywhere or send it from TeleBar."
    }

    func copySummary() {
        copyToPasteboard(summaryText)
        headline = "Summary copied"
        subheadline = "The summary is now on your clipboard."
    }

    func openBotFather() {
        openURL("https://t.me/BotFather")
    }

    func startNewBotFlow() {
        copyToPasteboard("/newbot")
        openBotFather()
        headline = "BotFather ready"
        subheadline = "Paste /newbot in Telegram to create the next bot."
    }

    func startInlineSetupFlow() {
        copyToPasteboard("/setinline")
        openBotFather()
        headline = "Inline setup ready"
        subheadline = "Paste /setinline in BotFather to enable @-style inline use."
    }

    func openBotChat() {
        guard let username = botUsername else {
            fail(headline: "Refresh the bot first.", subheadline: "TeleBar needs the bot username before it can open the chat.")
            return
        }
        openURL("https://t.me/\(username)")
    }

    func copyMentionHandle() {
        guard let username = botUsername else {
            fail(headline: "Refresh the bot first.", subheadline: "TeleBar needs the bot username before it can copy the handle.")
            return
        }
        copyToPasteboard("@\(username) ")
        headline = "Copied @\(username)"
        subheadline = "Drop it into Telegram for inline mentions or quick handoff."
    }

    func openAddToGroup() {
        guard let username = botUsername else {
            fail(headline: "Refresh the bot first.", subheadline: "TeleBar needs the bot username before it can build the group link.")
            return
        }
        let rights = "change_info+delete_messages+restrict_members+invite_users+pin_messages+manage_topics+manage_chat"
        openURL("https://t.me/\(username)?startgroup&admin=\(rights)")
    }

    func openAddToChannel() {
        guard let username = botUsername else {
            fail(headline: "Refresh the bot first.", subheadline: "TeleBar needs the bot username before it can build the channel link.")
            return
        }
        let rights = "post_messages+edit_messages+delete_messages+invite_users+manage_chat"
        openURL("https://t.me/\(username)?startchannel&admin=\(rights)")
    }

    func openAttachFlow() {
        guard let username = botUsername else {
            fail(headline: "Refresh the bot first.", subheadline: "TeleBar needs the bot username before it can build the attach link.")
            return
        }
        openURL("https://t.me/\(username)?startattach&choose=users+bots+groups+channels")
    }

    func quit() {
        NSApp.terminate(nil)
    }

    private func loadSecretsState() {
        hasStoredTelegramToken = !((try? keychain.read(account: Secrets.telegramToken)) ?? "").isEmpty
        hasStoredOpenAIKey = !((try? keychain.read(account: Secrets.openAIKey)) ?? "").isEmpty
    }

    private func applySentMessage(text: String, in thread: TelegramThread) {
        guard let botProfile else { return }
        let message = TelegramThreadMessage(
            id: -Int64(Date().timeIntervalSince1970),
            author: botProfile.firstName,
            text: text,
            date: Date(),
            isOutgoing: true
        )

        threads = threads.map { existing in
            guard existing.chatID == thread.chatID else { return existing }
            var updated = existing
            updated.latestText = text
            updated.latestDate = message.date
            updated.recentCount += 1
            updated.messages.insert(message, at: 0)
            return updated
        }
    }

    private func persistSelection() {
        defaults.set(selectedTab.rawValue, forKey: DefaultsKey.selectedTab)
        defaults.set(selectedChatID, forKey: DefaultsKey.selectedChatID)
    }

    private func persistDrafts() {
        defaults.set(selectedTone.rawValue, forKey: DefaultsKey.replyTone)
        defaults.set(instructionDraft, forKey: DefaultsKey.instructionDraft)
        defaults.set(composeText, forKey: DefaultsKey.composeText)
    }

    private func fail(headline: String, subheadline: String) {
        phase = .failure
        self.headline = headline
        self.subheadline = subheadline
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }

    private func copyToPasteboard(_ string: String) {
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
