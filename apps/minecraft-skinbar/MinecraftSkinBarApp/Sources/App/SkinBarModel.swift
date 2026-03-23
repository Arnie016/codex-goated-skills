import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class SkinBarModel: ObservableObject {
    enum Phase {
        case idle
        case running
        case success
        case failure

        var title: String {
            switch self {
            case .idle: return "Ready"
            case .running: return "Generating"
            case .success: return "Ready In Launcher"
            case .failure: return "Needs Attention"
            }
        }

        var color: NSColor {
            switch self {
            case .idle: return NSColor(calibratedRed: 0.61, green: 0.68, blue: 0.76, alpha: 1)
            case .running: return NSColor(calibratedRed: 0.25, green: 0.69, blue: 0.98, alpha: 1)
            case .success: return NSColor(calibratedRed: 0.28, green: 0.80, blue: 0.52, alpha: 1)
            case .failure: return NSColor(calibratedRed: 0.98, green: 0.62, blue: 0.26, alpha: 1)
            }
        }
    }

    private enum DefaultsKey {
        static let latestSkin = "minecraftSkinBar.latestSkin"
        static let latestPreview = "minecraftSkinBar.latestPreview"
        static let latestName = "minecraftSkinBar.latestName"
        static let latestPrompt = "minecraftSkinBar.latestPrompt"
        static let isSlim = "minecraftSkinBar.isSlim"
        static let apiKeyVisible = "minecraftSkinBar.apiKeyVisible"
    }

    private enum Secrets {
        static let service = "com.arnav.MinecraftSkinBar"
        static let apiAccount = "openai_api_key"
    }

    @Published var prompt: String = ""
    @Published var skinName: String = ""
    @Published var isSlimModel = false
    @Published var apiKeyDraft: String = ""
    @Published var isShowingAPIKeyField = false
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var headline: String = "Describe a skin and it will land in Minecraft."
    @Published private(set) var subheadline: String = "Prompt it, preview it, then select it in the launcher."
    @Published private(set) var latestSkinURL: URL?
    @Published private(set) var latestPreviewURL: URL?
    @Published private(set) var latestRawURL: URL?
    @Published private(set) var latestRegisteredID: String?
    @Published private(set) var latestOutputText: String = ""
    @Published private(set) var hasStoredAPIKey = false

    let outputDirectory = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("Pictures", isDirectory: true)
        .appendingPathComponent("Minecraft Skins", isDirectory: true)

    private let cli = SkinStudioCLI()
    private let defaults = UserDefaults.standard
    private let keychain = KeychainStore(service: Secrets.service)

    init() {
        prompt = defaults.string(forKey: DefaultsKey.latestPrompt) ?? ""
        skinName = defaults.string(forKey: DefaultsKey.latestName) ?? ""
        isSlimModel = defaults.bool(forKey: DefaultsKey.isSlim)
        isShowingAPIKeyField = defaults.bool(forKey: DefaultsKey.apiKeyVisible)
        loadAPIKeyStatus()
        restoreLatestFiles()
    }

    var isRunning: Bool { phase == .running }

    var menuBarSymbolName: String {
        if isRunning { return "sparkles.rectangle.stack.fill" }
        return latestPreviewURL == nil ? "tshirt.fill" : "tshirt"
    }

    var menuBarHelp: String {
        "\(phase.title) • \(headline)"
    }

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isRunning
    }

    var hasAnyAPIKey: Bool {
        hasStoredAPIKey || !cli.environmentAPIKey.isEmpty
    }

    var apiKeyStatusText: String {
        hasAnyAPIKey ? "AI ready" : "Add API key for Generate"
    }

    var canUseLatestSkin: Bool {
        latestSkinURL != nil
    }

    var canUseLatestPreview: Bool {
        latestPreviewURL != nil
    }

    var currentName: String {
        let trimmed = skinName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let url = latestSkinURL { return url.deletingPathExtension().lastPathComponent }
        return "Untitled Skin"
    }

    func generateFromPrompt() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }
        guard hasAnyAPIKey else {
            phase = .failure
            headline = "Add your OpenAI API key first."
            subheadline = "Import PNG works without AI. Prompt generation needs a saved key."
            isShowingAPIKeyField = true
            defaults.set(true, forKey: DefaultsKey.apiKeyVisible)
            return
        }

        let resolvedName = resolvedSkinName(from: trimmedPrompt)
        persistDraftState(name: resolvedName, prompt: trimmedPrompt)
        run(
            phase: .running,
            headline: "Generating \(resolvedName)...",
            subheadline: "Drafting a skin sheet, preview, and launcher entry."
        ) {
            try await self.cli.generateAndRegister(
                prompt: trimmedPrompt,
                name: resolvedName,
                slim: self.isSlimModel,
                outputDirectory: self.outputDirectory,
                apiKey: self.availableAPIKey
            )
        }
    }

    func importExistingSkin() {
        guard !isRunning else { return }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.title = "Choose A Minecraft Skin PNG"
        panel.message = "Pick a 64x64 or 64x32 skin PNG to add to the launcher."

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let resolvedName = resolvedSkinName(from: url.deletingPathExtension().lastPathComponent)
        persistDraftState(name: resolvedName, prompt: prompt)
        run(
            phase: .running,
            headline: "Importing \(resolvedName)...",
            subheadline: "Registering the PNG in your local Minecraft launcher."
        ) {
            try await self.cli.registerExistingSkin(
                skinURL: url,
                name: resolvedName,
                slim: self.isSlimModel,
                apiKey: self.availableAPIKey
            )
        }
    }

    func openLatestSkin() {
        guard let url = latestSkinURL else { return }
        NSWorkspace.shared.open(url)
    }

    func openLatestPreview() {
        guard let url = latestPreviewURL else { return }
        NSWorkspace.shared.open(url)
    }

    func revealLatestFiles() {
        let targets = [latestPreviewURL, latestSkinURL].compactMap { $0 }
        guard let first = targets.first else { return }
        NSWorkspace.shared.activateFileViewerSelecting([first])
    }

    func openOutputFolder() {
        NSWorkspace.shared.open(outputDirectory)
    }

    func openMinecraftLauncher() {
        cli.openLauncher()
    }

    func saveAPIKey() {
        let trimmed = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try keychain.write(trimmed, account: Secrets.apiAccount)
            apiKeyDraft = ""
            hasStoredAPIKey = true
            isShowingAPIKeyField = false
            defaults.set(false, forKey: DefaultsKey.apiKeyVisible)
            if phase == .failure {
                phase = .idle
                headline = "API key saved"
                subheadline = "Generate is ready again."
            }
        } catch {
            phase = .failure
            headline = "Couldn’t save the API key."
            subheadline = error.localizedDescription
        }
    }

    func toggleAPIKeyField() {
        isShowingAPIKeyField.toggle()
        defaults.set(isShowingAPIKeyField, forKey: DefaultsKey.apiKeyVisible)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    private func run(
        phase: Phase,
        headline: String,
        subheadline: String,
        operation: @escaping () async throws -> SkinStudioResult
    ) {
        self.phase = phase
        self.headline = headline
        self.subheadline = subheadline
        latestOutputText = ""

        Task {
            do {
                let result = try await operation()
                apply(result: result)
            } catch {
                self.phase = .failure
                self.headline = "Couldn’t finish that skin."
                self.subheadline = friendlyErrorMessage(for: error)
                if let cliError = error as? SkinStudioCLI.Error, !cliError.output.isEmpty {
                    latestOutputText = cliError.output
                }
            }
        }
    }

    private func apply(result: SkinStudioResult) {
        latestRawURL = result.rawURL
        latestSkinURL = result.skinURL
        latestPreviewURL = result.previewURL
        latestRegisteredID = result.registeredSkinID
        latestOutputText = result.outputText
        phase = .success

        if let id = result.registeredSkinID {
            headline = "Added to Minecraft as \(id)"
            subheadline = "If it doesn't appear right away, fully quit and reopen Minecraft Launcher."
        } else if let skinURL = result.skinURL {
            headline = "Skin ready: \(skinURL.deletingPathExtension().lastPathComponent)"
            subheadline = "Preview it or import it into the launcher next."
        } else {
            headline = "Done"
            subheadline = "Your latest skin files are ready."
        }

        persistLatestFiles()
    }

    private func resolvedSkinName(from seed: String) -> String {
        let explicit = skinName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !explicit.isEmpty { return explicit }
        let compact = seed
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return compact.isEmpty ? "minecraft-skin" : compact
    }

    private func persistDraftState(name: String, prompt: String) {
        defaults.set(name, forKey: DefaultsKey.latestName)
        defaults.set(prompt, forKey: DefaultsKey.latestPrompt)
        defaults.set(isSlimModel, forKey: DefaultsKey.isSlim)
        skinName = name
        self.prompt = prompt
    }

    private func persistLatestFiles() {
        defaults.set(latestSkinURL?.path, forKey: DefaultsKey.latestSkin)
        defaults.set(latestPreviewURL?.path, forKey: DefaultsKey.latestPreview)
        defaults.set(currentName, forKey: DefaultsKey.latestName)
        defaults.set(prompt, forKey: DefaultsKey.latestPrompt)
        defaults.set(isSlimModel, forKey: DefaultsKey.isSlim)
    }

    private func restoreLatestFiles() {
        if let skinPath = defaults.string(forKey: DefaultsKey.latestSkin) {
            let url = URL(fileURLWithPath: skinPath)
            if FileManager.default.fileExists(atPath: url.path) {
                latestSkinURL = url
            }
        }

        if let previewPath = defaults.string(forKey: DefaultsKey.latestPreview) {
            let url = URL(fileURLWithPath: previewPath)
            if FileManager.default.fileExists(atPath: url.path) {
                latestPreviewURL = url
                phase = .success
                headline = "Latest skin ready"
                subheadline = "Pick up where you left off."
            }
        }
    }

    private var availableAPIKey: String? {
        if let storedValue = try? keychain.read(account: Secrets.apiAccount), !storedValue.isEmpty {
            return storedValue
        }
        return cli.environmentAPIKey.isEmpty ? nil : cli.environmentAPIKey
    }

    private func loadAPIKeyStatus() {
        hasStoredAPIKey = ((try? keychain.read(account: Secrets.apiAccount)) ?? nil)?.isEmpty == false
    }

    private func friendlyErrorMessage(for error: Swift.Error) -> String {
        if let cliError = error as? SkinStudioCLI.Error {
            let output = cliError.output
            if output.contains("OPENAI_API_KEY is not set") {
                return "Missing API key. Save it in the app once, then Generate will work."
            }
            if output.contains("No module named 'PIL'") || output.contains("Pillow is required") {
                return "The app couldn’t find its image runtime. This build now fixes that, so try again."
            }
            if output.contains("uv is required") {
                return "The app couldn’t find uv. It should use the Homebrew install on this Mac."
            }
            return cliError.message
        }
        return error.localizedDescription
    }
}
