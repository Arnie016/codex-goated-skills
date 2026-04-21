import AppKit
import Foundation

@MainActor
final class SkillBarModel: ObservableObject {
    private enum DefaultsKey {
        static let selectedSection = "skillBar.selectedSection"
        static let repoRootPath = "skillBar.repoRootPath"
        static let skillsDirectoryPath = "skillBar.skillsDirectoryPath"
        static let searchText = "skillBar.searchText"
    }

    @Published var selectedSection: SkillBarSection = .discover {
        didSet { defaults.set(selectedSection.rawValue, forKey: DefaultsKey.selectedSection) }
    }
    @Published var searchText = "" {
        didSet { defaults.set(searchText, forKey: DefaultsKey.searchText) }
    }
    @Published private(set) var entries: [SkillCatalogEntry] = []
    @Published private(set) var packEntries: [SkillPackEntry] = []
    @Published private(set) var presets: [SkillPreset] = []
    @Published private(set) var repoRootPath: String?
    @Published var installedSkillsPath: String
    @Published private(set) var statusHeadline = "Ready to manage goated skills and packs."
    @Published private(set) var statusDetail = "Browse, install, update, and refresh skills or packs from the top bar."
    @Published private(set) var isBusy = false
    @Published private(set) var activeCommandLabel: String?
    @Published private(set) var activeSkillIDs: Set<String> = []
    @Published var pendingPreset: SkillPreset?
    @Published private(set) var lastCommandOutput = ""

    private let defaults = UserDefaults.standard
    private let catalogService = SkillCatalogService()
    private let installService = SkillInstallService()

    init() {
        installedSkillsPath = defaults.string(forKey: DefaultsKey.skillsDirectoryPath) ?? (NSHomeDirectory() + "/.codex/skills")
        if let raw = defaults.string(forKey: DefaultsKey.selectedSection),
           let section = SkillBarSection(rawValue: raw) {
            selectedSection = section
        }
        searchText = defaults.string(forKey: DefaultsKey.searchText) ?? ""
        repoRootPath = defaults.string(forKey: DefaultsKey.repoRootPath) ?? catalogService.resolveDefaultRepoRoot()
        presets = Self.defaultPresets
        refreshCatalog()
    }

    var filteredEntries: [SkillCatalogEntry] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return entries }
        let query = searchText.lowercased()
        return entries.filter { entry in
            entry.id.lowercased().contains(query) ||
            entry.displayName.lowercased().contains(query) ||
            entry.primaryDescription.lowercased().contains(query) ||
            entry.category.rawValue.lowercased().contains(query)
        }
    }

    var discoverEntries: [SkillCatalogEntry] { filteredEntries }
    var installedEntries: [SkillCatalogEntry] { filteredEntries.filter(\.isInstalled) }

    var filteredPackEntries: [SkillPackEntry] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return packEntries }
        let query = searchText.lowercased()
        return packEntries.filter { entry in
            entry.id.lowercased().contains(query) ||
            entry.title.lowercased().contains(query) ||
            entry.primaryDescription.lowercased().contains(query) ||
            entry.includedSkillIDs.joined(separator: " ").lowercased().contains(query)
        }
    }

    var hasValidRepo: Bool {
        guard let repoRootPath else { return false }
        return catalogService.isRepoRoot(at: repoRootPath)
    }

    var menuBarHelp: String {
        if let activeCommandLabel {
            return "SkillBar • \(activeCommandLabel)"
        }
        return "SkillBar • \(statusHeadline)"
    }

    var installedCount: Int { entries.filter(\.isInstalled).count }
    var availableCount: Int { entries.count }
    var packCount: Int { packEntries.count }
    var installedPackCount: Int { packEntries.filter(\.isComplete).count }
    var missingIconCount: Int { entries.filter { $0.iconSmallPath == nil && $0.iconLargePath == nil }.count }
    var duplicateNameCount: Int {
        Dictionary(grouping: entries) { entry in
            entry.displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        .values
        .filter { $0.count > 1 }
        .reduce(0) { $0 + $1.count }
    }
    var catalogQualityLabel: String {
        let issueCount = missingIconCount + duplicateNameCount
        return issueCount == 0 ? "clean" : "\(issueCount) to review"
    }

    func action(for entry: SkillCatalogEntry) -> SkillCommandAction {
        entry.isInstalled ? .update : .install
    }

    func action(for pack: SkillPackEntry) -> SkillCommandAction {
        pack.isComplete ? .update : .install
    }

    func isRunning(_ entry: SkillCatalogEntry) -> Bool {
        activeSkillIDs.contains(entry.id)
    }

    func refreshCatalog() {
        presets = Self.defaultPresets

        guard let repoRootPath, hasValidRepo else {
            entries = []
            packEntries = []
            statusHeadline = "Choose a full repo clone."
            statusDetail = "SkillBar needs a local clone with `skills/` and `bin/codex-goated` before it can show the catalog or install skills."
            return
        }

        do {
            entries = try catalogService.loadCatalog(repoRootPath: repoRootPath, installedSkillsPath: installedSkillsPath)
        } catch {
            entries = []
            packEntries = []
            statusHeadline = "Couldn’t load the skill catalog."
            statusDetail = error.localizedDescription
            return
        }

        do {
            packEntries = try catalogService.loadPacks(repoRootPath: repoRootPath, installedSkillsPath: installedSkillsPath)
        } catch {
            packEntries = []
            statusHeadline = "Catalog ready"
            statusDetail = "\(entries.count) skills found, pack metadata could not be loaded: \(error.localizedDescription)"
            return
        }

        statusHeadline = "Catalog ready"
        statusDetail = "\(entries.count) skills and \(packEntries.count) packs found, \(installedCount) skills installed, \(installedPackCount) packs ready."
    }

    func chooseRepoRoot() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Repo"
        panel.message = "Choose your local codex-goated-skills repo clone."

        if panel.runModal() == .OK, let url = panel.url {
            repoRootPath = url.path
            defaults.set(url.path, forKey: DefaultsKey.repoRootPath)
            refreshCatalog()
        }
    }

    func chooseInstalledSkillsFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Folder"
        panel.message = "Choose the folder where Codex skills are installed."

        if panel.runModal() == .OK, let url = panel.url {
            installedSkillsPath = url.path
            defaults.set(url.path, forKey: DefaultsKey.skillsDirectoryPath)
            refreshCatalog()
        }
    }

    func runAction(for entry: SkillCatalogEntry) {
        run(request: SkillCommandRequest(
            action: action(for: entry),
            skillIDs: [entry.id],
            repoRootPath: repoRootPath ?? "",
            destinationPath: installedSkillsPath
        ), label: "\(action(for: entry).buttonTitle) \(entry.displayName)")
    }

    func runAction(for pack: SkillPackEntry) {
        run(request: SkillCommandRequest(
            action: action(for: pack),
            skillIDs: pack.includedSkillIDs,
            repoRootPath: repoRootPath ?? "",
            destinationPath: installedSkillsPath
        ), label: "\(action(for: pack).buttonTitle) \(pack.title)")
    }

    func runCatalogCheck() {
        runRepoHealthAction(action: .catalogCheck, label: "Catalog Check")
    }

    func runAudit() {
        runRepoHealthAction(action: .audit, label: "Audit")
    }

    func revealSkillInFinder(_ entry: SkillCatalogEntry) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: entry.skillPath)])
    }

    func revealRepoInFinder() {
        guard let repoRootPath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: repoRootPath)])
    }

    func revealInstalledSkillsFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: installedSkillsPath)])
    }

    func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func requestPresetEnable(_ preset: SkillPreset) {
        pendingPreset = preset
    }

    func cancelPresetRequest() {
        pendingPreset = nil
    }

    func enablePendingPreset() {
        guard let preset = pendingPreset else { return }
        pendingPreset = nil
        let installable = preset.includedSkillIDs.filter { id in entries.contains(where: { $0.id == id }) }
        run(request: SkillCommandRequest(
            action: .install,
            skillIDs: installable,
            repoRootPath: repoRootPath ?? "",
            destinationPath: installedSkillsPath
        ), label: "Enable \(preset.title)")
    }

    private func run(request: SkillCommandRequest, label: String) {
        guard hasValidRepo else {
            statusHeadline = "Repo path missing"
            statusDetail = "Choose a local clone with `skills/` and `bin/codex-goated` first."
            selectedSection = .setup
            return
        }

        isBusy = true
        activeCommandLabel = label
        activeSkillIDs = Set(request.skillIDs)
        statusHeadline = label
        statusDetail = "Running through codex-goated..."

        Task {
            do {
                let result = try await installService.run(request)
                lastCommandOutput = result.output
                refreshCatalog()
                statusHeadline = "\(label) complete"
                statusDetail = result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "SkillBar finished without extra output."
                    : result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                statusHeadline = "\(label) failed"
                statusDetail = error.localizedDescription
            }
            activeSkillIDs = []
            activeCommandLabel = nil
            isBusy = false
        }
    }

    func presetEntries(_ preset: SkillPreset) -> [SkillCatalogEntry] {
        preset.includedSkillIDs.compactMap { id in entries.first(where: { $0.id == id }) }
    }

    func packMembers(for pack: SkillPackEntry) -> [SkillCatalogEntry] {
        pack.includedSkillIDs.compactMap { id in entries.first(where: { $0.id == id }) }
    }

    private func runRepoHealthAction(action: SkillCommandAction, label: String) {
        run(request: SkillCommandRequest(
            action: action,
            skillIDs: [],
            repoRootPath: repoRootPath ?? "",
            destinationPath: installedSkillsPath
        ), label: label)
    }

    static let defaultPresets: [SkillPreset] = [
        SkillPreset(id: "telegram-ops", title: "Telegram Ops", summary: "TeleBar plus Context Assembly for operator handoff, thread drafting, and escalation packs.", includedSkillIDs: ["telebar", "clipboard-studio"]),
        SkillPreset(id: "network-sentinel", title: "Network Sentinel", summary: "Local network monitoring plus Telegram delivery for cleaner alerting and operator follow-up.", includedSkillIDs: ["network-studio", "telebar"]),
        SkillPreset(id: "field-desk", title: "Field Desk", summary: "Phone recovery and field coordination flows that pair provider-aware handoffs with Telegram control.", includedSkillIDs: ["find-my-phone-studio", "telebar"]),
        SkillPreset(id: "launch-kit", title: "Launch Kit", summary: "The core go-to set for turning a rough project into a polished, publishable package.", includedSkillIDs: ["repo-launch", "content-pack", "brand-kit"]),
        SkillPreset(id: "utility-builder", title: "Utility Builder", summary: "A focused tool-making bundle for productivity, monitoring, and Mac utility workflows.", includedSkillIDs: ["clipboard-studio", "network-studio", "find-my-phone-studio"])
    ]
}
