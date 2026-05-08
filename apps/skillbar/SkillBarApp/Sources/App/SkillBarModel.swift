import AppKit
import Foundation

@MainActor
final class SkillBarModel: ObservableObject {
    typealias CommandRunner = @Sendable (SkillCommandRequest) async throws -> SkillCommandResult

    private enum DefaultsKey {
        static let selectedSection = "skillBar.selectedSection"
        static let repoRootPath = "skillBar.repoRootPath"
        static let skillsDirectoryPath = "skillBar.skillsDirectoryPath"
        static let searchText = "skillBar.searchText"
        static let menuBarSkillID = "skillBar.menuBarSkillID"
        static let menuBarSnapshot = "skillBar.menuBarSnapshot"
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
    @Published private(set) var repoRootSelectionContext: RepoRootSelectionContext?
    @Published private(set) var suggestedRepoRoots: [String] = []
    @Published private(set) var menuBarSnapshot: PinnedMenuBarEntrySnapshot?
    @Published private(set) var focusedPackID: String?
    @Published private(set) var focusedPackTitle: String?
    @Published private(set) var focusedSkillIDs: Set<String> = []
    @Published var menuBarSkillID: String? {
        didSet {
            if let menuBarSkillID, !menuBarSkillID.isEmpty {
                defaults.set(menuBarSkillID, forKey: DefaultsKey.menuBarSkillID)
            } else {
                defaults.removeObject(forKey: DefaultsKey.menuBarSkillID)
            }
        }
    }
    @Published var installedSkillsPath: String
    @Published private(set) var statusHeadline = "Ready to manage goated skills and packs."
    @Published private(set) var statusDetail = "Browse, install, update, and refresh skills or packs from the top bar."
    @Published private(set) var isBusy = false
    @Published private(set) var activeCommandLabel: String?
    @Published private(set) var activePackID: String?
    @Published private(set) var activeSkillIDs: Set<String> = []
    @Published var pendingPreset: SkillPreset?
    @Published private(set) var lastCommandOutput = ""

    private let defaults: UserDefaults
    private let catalogService: SkillCatalogService
    private let runCommand: CommandRunner

    init(
        defaults: UserDefaults = .standard,
        catalogService: SkillCatalogService? = nil,
        installService: SkillInstallService = SkillInstallService(),
        repoRootPathOverride: String? = nil,
        installedSkillsPathOverride: String? = nil,
        commandRunner: CommandRunner? = nil,
        autoRefresh: Bool = true
    ) {
        self.defaults = defaults
        let resolvedCatalogService = catalogService ?? Self.defaultCatalogService(repoRootPathOverride: repoRootPathOverride)
        self.catalogService = resolvedCatalogService
        self.runCommand = commandRunner ?? { request in
            try await installService.run(request)
        }

        installedSkillsPath = installedSkillsPathOverride ?? defaults.string(forKey: DefaultsKey.skillsDirectoryPath) ?? (NSHomeDirectory() + "/.codex/skills")
        if let raw = defaults.string(forKey: DefaultsKey.selectedSection),
           let section = SkillBarSection(rawValue: raw) {
            selectedSection = section
        }
        searchText = defaults.string(forKey: DefaultsKey.searchText) ?? ""
        let storedRepoRoot = repoRootPathOverride ?? defaults.string(forKey: DefaultsKey.repoRootPath)
        let normalizedRepoRoot = resolvedCatalogService.normalizedRepoRoot(startingAt: storedRepoRoot)
        let defaultRepoRoot = resolvedCatalogService.resolveDefaultRepoRoot()
        repoRootPath = normalizedRepoRoot ?? storedRepoRoot ?? defaultRepoRoot
        repoRootSelectionContext = Self.repoRootSelectionContext(
            requestedPath: storedRepoRoot,
            resolvedPath: repoRootPath,
            fallbackPath: defaultRepoRoot,
            selectionMode: repoRootPathOverride == nil ? .restored : .manual
        )
        if let normalizedRepoRoot {
            defaults.set(normalizedRepoRoot, forKey: DefaultsKey.repoRootPath)
        }
        suggestedRepoRoots = resolvedCatalogService.suggestedRepoRoots()
        menuBarSkillID = defaults.string(forKey: DefaultsKey.menuBarSkillID)
        menuBarSnapshot = Self.loadMenuBarSnapshot(from: defaults)
        presets = Self.defaultPresets
        if autoRefresh {
            refreshCatalog()
        }
    }

    private static func defaultCatalogService(repoRootPathOverride: String?) -> SkillCatalogService {
        guard let repoRootPathOverride else {
            return SkillCatalogService()
        }

        let repoURL = URL(fileURLWithPath: repoRootPathOverride, isDirectory: true).standardizedFileURL
        let probe = SkillCatalogService()
        let discoveryRoot = FileManager.default.fileExists(atPath: repoURL.path) && probe.isRepoRoot(at: repoURL.path)
            ? repoURL.deletingLastPathComponent().path
            : repoURL.path
        return SkillCatalogService(repoDiscoveryStartPaths: [discoveryRoot])
    }

    var filteredEntries: [SkillCatalogEntry] {
        let focusedEntries = entries.filter { entry in
            focusedSkillIDs.isEmpty || focusedSkillIDs.contains(entry.id)
        }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return focusedEntries }
        let query = searchText.lowercased()
        return focusedEntries.filter { entry in
            entry.id.lowercased().contains(query) ||
            entry.displayName.lowercased().contains(query) ||
            entry.primaryDescription.lowercased().contains(query) ||
            entry.longDescription.lowercased().contains(query) ||
            entry.categoryLabel.lowercased().contains(query) ||
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
        if let menuBarSelection {
            return "SkillBar • \(menuBarSelection.displayName) on the menu bar"
        }
        return "SkillBar • \(statusHeadline)"
    }

    var menuBarEntry: SkillCatalogEntry? {
        guard let menuBarSkillID else { return nil }
        return entries.first(where: { $0.id == menuBarSkillID })
    }

    var menuBarSelection: PinnedMenuBarEntrySnapshot? {
        menuBarEntry?.menuBarSnapshot ?? menuBarSnapshot
    }
    var menuBarInstallRecoveryEntry: SkillCatalogEntry? {
        guard let menuBarEntry, !menuBarEntry.isInstalled else { return nil }
        return menuBarEntry
    }
    var hasPinnedMenuBarSelection: Bool {
        menuBarSelection != nil
    }
    var hasUnavailablePinnedMenuBarSelection: Bool {
        hasPinnedMenuBarSelection && !canRevealPinnedMenuBarEntry
    }
    var canRevealPinnedMenuBarEntry: Bool {
        menuBarEntry != nil
    }
    var menuBarRevealButtonTitle: String {
        if canRevealPinnedMenuBarEntry {
            return "Open Pinned Tile"
        }
        if hasUnavailablePinnedMenuBarSelection {
            return "Pinned Tile Missing"
        }
        return "Pin an Icon First"
    }
    var menuBarRevealDetail: String {
        if canRevealPinnedMenuBarEntry {
            return "Jump straight to the pinned icon tile in the current catalog."
        }
        if hasUnavailablePinnedMenuBarSelection {
            return "The pinned icon came from an older or different repo selection, so there is no live catalog tile to open right now."
        }
        return "Pin a skill icon first if you want a direct jump back to the current menu bar icon."
    }
    var unavailablePinnedMenuBarRecoveryDetail: String {
        "The saved pinned icon is no longer available in the current catalog, so SkillBar can switch back to the default stack icon."
    }
    var menuBarRecoveryRepoRoot: String? {
        guard hasUnavailablePinnedMenuBarSelection else { return nil }
        return preferredDetectedRepoRoot
    }
    var hasMenuBarRecoveryRepoShortcut: Bool {
        menuBarRecoveryRepoRoot != nil
    }
    var menuBarRecoveryActionLabel: String {
        primaryRepoActionLabel(
            usesCurrentSelection: false,
            installsFolderExists: installedSkillsFolderExists
        )
    }
    var menuBarRecoveryRepoDisplayPath: String? {
        Self.abbreviatedPath(menuBarRecoveryRepoRoot)
    }
    var menuBarSelectionDisplayName: String {
        menuBarSelection?.displayName ?? "Default SkillBar icon"
    }

    var hasSearchText: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var hasPackFocus: Bool {
        focusedPackTitle != nil || !focusedSkillIDs.isEmpty
    }
    var hasActiveCatalogScope: Bool {
        hasSearchText || hasPackFocus
    }

    var installedCount: Int { entries.filter(\.isInstalled).count }
    var availableCount: Int { entries.count }
    var packCount: Int { packEntries.count }
    var installedPackCount: Int { packEntries.filter(\.isComplete).count }
    var defaultInstalledSkillsPath: String { NSHomeDirectory() + "/.codex/skills" }
    var installedSkillsFolderExists: Bool {
        directoryExists(at: installedSkillsPath)
    }
    var repoRootDisplayName: String { Self.displayName(for: repoRootPath) ?? "Repo not set" }
    var repoRootDisplayPath: String { Self.abbreviatedPath(repoRootPath) ?? "Not set" }
    var installedSkillsDisplayName: String { Self.displayName(for: installedSkillsPath) ?? installedSkillsPath }
    var installedSkillsDisplayPath: String { Self.abbreviatedPath(installedSkillsPath) ?? installedSkillsPath }
    var usesDefaultInstalledSkillsPath: Bool {
        URL(fileURLWithPath: installedSkillsPath, isDirectory: true).standardizedFileURL.path ==
            URL(fileURLWithPath: defaultInstalledSkillsPath, isDirectory: true).standardizedFileURL.path
    }
    var repoSelectionBadge: String { repoRootSelectionContext?.badge ?? "Manual" }
    var repoSelectionDetail: String {
        repoRootSelectionContext?.detail ?? "Choose a local codex-goated-skills clone to control exactly where SkillBar reads metadata and runs installs."
    }
    var repoSelectionSourcePath: String? {
        Self.abbreviatedPath(repoRootSelectionContext?.sourcePath)
    }
    var repoLabelCandidates: [String] {
        var candidates = suggestedRepoRoots
        if let repoRootPath {
            candidates.append(repoRootPath)
        }
        return Self.normalizedUniquePaths(candidates)
    }
    var preferredDetectedRepoRoot: String? {
        alternateSuggestedRepoRoots.first
    }
    var quickSetupRepoRoot: String? {
        if let preferredDetectedRepoRoot {
            return preferredDetectedRepoRoot
        }
        return hasValidRepo ? repoRootPath : nil
    }
    var quickSetupUsesCurrentRepoSelection: Bool {
        guard let quickSetupRepoRoot, let repoRootPath else { return false }
        return URL(fileURLWithPath: quickSetupRepoRoot, isDirectory: true).standardizedFileURL.path ==
            URL(fileURLWithPath: repoRootPath, isDirectory: true).standardizedFileURL.path
    }
    var packRecoveryRepoRoot: String? {
        preferredDetectedRepoRoot
    }
    var hasPackRecoveryRepoShortcut: Bool {
        packRecoveryRepoRoot != nil
    }
    var packRecoveryRepoDisplayPath: String? {
        Self.abbreviatedPath(packRecoveryRepoRoot)
    }
    var packRecoveryUsesCurrentRepoSelection: Bool {
        guard let packRecoveryRepoRoot, let repoRootPath else { return false }
        return URL(fileURLWithPath: packRecoveryRepoRoot, isDirectory: true).standardizedFileURL.path ==
            URL(fileURLWithPath: repoRootPath, isDirectory: true).standardizedFileURL.path
    }
    var canAccessQuickSetupRepoRoot: Bool {
        quickSetupRepoRoot != nil
    }
    var hasRecoverableRepoRootSelection: Bool {
        guard let repoRootPath else { return false }
        return directoryExists(at: repoRootPath)
    }
    var staleRepoSelectionDetail: String? {
        guard !hasValidRepo,
              preferredDetectedRepoRoot == nil,
              let repoRootPath else { return nil }
        let displayPath = Self.abbreviatedPath(repoRootPath) ?? repoRootPath
        return "\(displayPath) is still selected, but it is not a full repo clone with `skills/` and `bin/codex-goated`."
    }
    var alternateSuggestedRepoRoots: [String] {
        guard let repoRootPath else { return suggestedRepoRoots }
        let standardized = URL(fileURLWithPath: repoRootPath, isDirectory: true).standardizedFileURL.path
        return suggestedRepoRoots.filter { $0 != standardized }
    }
    var missingIconCount: Int { entries.filter { $0.iconSmallPath == nil && $0.iconLargePath == nil }.count }
    var duplicateNameCount: Int { duplicateNameCount(in: entries) }

    func duplicateNameCount(in entries: [SkillCatalogEntry]) -> Int {
        Dictionary(grouping: entries) { entry in
            entry.displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        .values
        .filter { $0.count > 1 }
        .reduce(0) { $0 + $1.count }
    }

    func duplicateNameIDs(in entries: [SkillCatalogEntry]) -> Set<String> {
        Set(
            Dictionary(grouping: entries) { entry in
                entry.displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
            .values
            .filter { $0.count > 1 }
            .flatMap { $0.map(\.id) }
        )
    }
    var catalogQualityLabel: String {
        let issueCount = missingIconCount + duplicateNameCount
        return issueCount == 0 ? "clean" : "\(issueCount) to review"
    }
    var hasRecentCommandOutput: Bool {
        !lastCommandOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var pinnedSkillIsOutsideFocusedPack: Bool {
        guard let menuBarSkillID, !focusedSkillIDs.isEmpty else { return false }
        return !focusedSkillIDs.contains(menuBarSkillID)
    }

    func action(for entry: SkillCatalogEntry) -> SkillCommandAction {
        entry.isInstalled ? .update : .install
    }

    func iconPrimaryAction(for entry: SkillCatalogEntry) -> SkillIconPrimaryAction {
        if menuBarSkillID == entry.id, entry.isInstalled {
            return .useDefaultIcon
        }
        if menuBarSkillID == entry.id {
            return .installPinnedSkill
        }
        if entry.isInstalled {
            return .pinToMenuBar
        }
        return .installAndPin
    }

    func catalogRowAccessoryAction(for entry: SkillCatalogEntry) -> SkillCatalogRowAccessoryAction {
        if menuBarSkillID == entry.id, entry.isInstalled {
            return .useDefaultIcon
        }
        if menuBarSkillID == entry.id {
            return .installPinnedSkill
        }
        if entry.isInstalled {
            return .pinToMenuBar
        }
        return .installAndPin
    }

    func action(for pack: SkillPackEntry) -> SkillCommandAction {
        pack.isComplete ? .update : .install
    }

    func isRunning(_ entry: SkillCatalogEntry) -> Bool {
        activeSkillIDs.contains(entry.id)
    }

    func isFocused(_ pack: SkillPackEntry) -> Bool {
        focusedPackID == pack.id
    }

    func canOpenFocusedPackCatalog(_ pack: SkillPackEntry) -> Bool {
        isFocused(pack) && !pack.hasNoAvailableMembers
    }

    func isRunning(_ pack: SkillPackEntry) -> Bool {
        activePackID == pack.id
    }

    func refreshCatalog() {
        presets = Self.defaultPresets
        refreshRepoSuggestions()

        guard let repoRootPath, hasValidRepo else {
            resetPackFocus()
            entries = []
            packEntries = []
            statusHeadline = "Choose a full repo clone."
            statusDetail = "SkillBar needs a local clone with `skills/` and `bin/codex-goated` before it can show the catalog or install skills."
            return
        }

        do {
            entries = try catalogService.loadCatalog(repoRootPath: repoRootPath, installedSkillsPath: installedSkillsPath)
        } catch {
            resetPackFocus()
            entries = []
            packEntries = []
            statusHeadline = "Couldn’t load the skill catalog."
            statusDetail = error.localizedDescription
            return
        }

        do {
            packEntries = try catalogService.loadPacks(repoRootPath: repoRootPath, installedSkillsPath: installedSkillsPath)
        } catch {
            resetPackFocus()
            packEntries = []
            statusHeadline = "Catalog ready"
            statusDetail = "\(entries.count) skills found, pack metadata could not be loaded: \(error.localizedDescription)"
            return
        }

        reconcilePackFocus()

        if let menuBarEntry {
            storeMenuBarSnapshot(menuBarEntry.menuBarSnapshot)
        }

        updateCatalogReadyStatus()
    }

    func chooseRepoRoot() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Repo"
        panel.message = "Choose your local codex-goated-skills repo clone."

        if panel.runModal() == .OK, let url = panel.url {
            useRepoRoot(url.path)
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

    func useDefaultInstalledSkillsFolder() {
        installedSkillsPath = defaultInstalledSkillsPath
        defaults.set(defaultInstalledSkillsPath, forKey: DefaultsKey.skillsDirectoryPath)
        refreshCatalog()
    }

    func createInstalledSkillsFolderIfNeeded() {
        do {
            try ensureInstalledSkillsFolderExists()
            statusHeadline = "Installs folder ready"
            statusDetail = "\(installedSkillsDisplayPath) is ready for SkillBar installs and updates."
        } catch {
            statusHeadline = "Couldn’t create installs folder"
            statusDetail = error.localizedDescription
        }
    }

    func useSuggestedRepoRoot(_ path: String) {
        useRepoRoot(path, selectionMode: .detected)
    }

    func completeQuickSetup(usingRepoRoot path: String) {
        if shouldSwitchQuickSetupRepo(to: path) {
            useSuggestedRepoRoot(path)
        }

        guard hasValidRepo else {
            statusHeadline = "Repo still missing"
            statusDetail = "Choose a local clone with `skills/` and `bin/codex-goated` before finishing setup."
            selectedSection = .setup
            return
        }

        do {
            try ensureInstalledSkillsFolderExists()
            updateCatalogReadyStatus()
            statusHeadline = "Quick setup ready"
            statusDetail = "\(repoRootDisplayName) is active and \(installedSkillsDisplayPath) is ready for installs and updates."
        } catch {
            statusHeadline = "Repo ready, installs folder blocked"
            statusDetail = error.localizedDescription
            selectedSection = .setup
        }
    }

    func completeQuickSetup() {
        guard let quickSetupRepoRoot else {
            statusHeadline = "Repo path missing"
            statusDetail = "Choose a local clone with `skills/` and `bin/codex-goated` before finishing setup."
            selectedSection = .setup
            return
        }

        completeQuickSetup(usingRepoRoot: quickSetupRepoRoot)
    }

    func completePackRecoveryQuickSetup() {
        guard let packRecoveryRepoRoot else {
            selectedSection = .setup
            return
        }

        completeQuickSetup(usingRepoRoot: packRecoveryRepoRoot)
    }

    func completeMenuBarRecoveryQuickSetup() {
        guard let menuBarRecoveryRepoRoot else {
            selectedSection = .setup
            return
        }

        completeQuickSetup(usingRepoRoot: menuBarRecoveryRepoRoot)
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
        guard pack.canRunInstallAction else {
            let missing = pack.unresolvedSkillIDs.joined(separator: ", ")
            statusHeadline = "\(pack.title) needs repo cleanup"
            statusDetail = missing.isEmpty
                ? "This pack has no installable skills in the current repo. Browse the pack to inspect what is missing."
                : "Broken pack references: \(missing). Browse the pack to inspect the available members while the metadata is fixed."
            selectedSection = .packs
            return
        }

        run(request: SkillCommandRequest(
            action: action(for: pack),
            skillIDs: [],
            packID: pack.id,
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

    func runDevelopmentLoop() {
        runRepoHealthAction(action: .develop, label: "Dev Loop")
    }

    func clearSearch() {
        searchText = ""
    }

    func clearCommandOutput() {
        lastCommandOutput = ""
    }

    func focusOnPack(_ pack: SkillPackEntry) {
        focusedPackID = pack.id
        focusedPackTitle = pack.title
        focusedSkillIDs = resolvedPackSkillIDs(for: pack)
        guard !isBusy else { return }
        statusHeadline = "Browsing \(pack.title)"
        statusDetail = packFocusStatusDetail(for: pack)
    }

    func browsePack(_ pack: SkillPackEntry) {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchText = ""
        }
        focusOnPack(pack)
        selectedSection = pack.hasNoAvailableMembers ? .packs : .discover
    }

    func browsePackIcons(_ pack: SkillPackEntry) {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchText = ""
        }
        focusOnPack(pack)
        selectedSection = pack.hasNoAvailableMembers ? .packs : .icons
    }

    func clearPackFocus() {
        guard focusedPackID != nil || focusedPackTitle != nil || !focusedSkillIDs.isEmpty else { return }
        focusedPackID = nil
        focusedPackTitle = nil
        focusedSkillIDs = []

        guard !isBusy else { return }

        if hasValidRepo {
            updateCatalogReadyStatus()
        } else {
            statusHeadline = "Choose a full repo clone."
            statusDetail = "SkillBar needs a local clone with `skills/` and `bin/codex-goated` before it can show the catalog or install skills."
        }
    }

    func preparePinnedIconRevealScope() {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchText = ""
        }

        if pinnedSkillIsOutsideFocusedPack {
            clearPackFocus()
        }
    }

    func revealSkillInFinder(_ entry: SkillCatalogEntry) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: entry.skillPath)])
    }

    func revealRepoInFinder() {
        guard let repoRootPath, hasRecoverableRepoRootSelection else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: repoRootPath)])
    }

    func openRepoRoot() {
        guard let repoRootPath, hasRecoverableRepoRootSelection else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: repoRootPath, isDirectory: true))
    }

    func openQuickSetupRepoRoot() {
        guard let quickSetupRepoRoot else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: quickSetupRepoRoot, isDirectory: true))
    }

    func openMenuBarRecoveryRepoRoot() {
        guard let menuBarRecoveryRepoRoot else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: menuBarRecoveryRepoRoot, isDirectory: true))
    }

    func revealMenuBarRecoveryRepoRootInFinder() {
        guard let menuBarRecoveryRepoRoot else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: menuBarRecoveryRepoRoot)])
    }

    func revealQuickSetupRepoRootInFinder() {
        guard let quickSetupRepoRoot else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: quickSetupRepoRoot)])
    }

    func openPackRecoveryRepoRoot() {
        guard let packRecoveryRepoRoot else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: packRecoveryRepoRoot, isDirectory: true))
    }

    func revealPackRecoveryRepoRootInFinder() {
        guard let packRecoveryRepoRoot else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: packRecoveryRepoRoot)])
    }

    func revealInstalledSkillsFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: installedSkillsPath)])
    }

    func openInstalledSkillsFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: installedSkillsPath, isDirectory: true))
    }

    func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func requestPresetEnable(_ preset: SkillPreset) {
        let installable = installablePresetSkillIDs(for: preset)
        guard !installable.isEmpty else {
            pendingPreset = nil
            statusHeadline = "\(preset.title) has no available skills"
            let missing = missingPresetSkillIDs(for: preset)
            statusDetail = missing.isEmpty
                ? "This preset does not map to any installable skills in the current repo."
                : "Missing from the current repo: \(missing.joined(separator: ", "))."
            selectedSection = .presets
            return
        }
        pendingPreset = preset
    }

    func setMenuBarEntry(_ entry: SkillCatalogEntry) {
        persistMenuBarSelection(for: entry)
        statusHeadline = "\(entry.displayName) is on the menu bar"
        statusDetail = entry.isInstalled
            ? "SkillBar now uses this installed skill icon in the menu bar."
            : "SkillBar now uses this skill icon in the menu bar. Use Install + Pin if you want the real skill available in Codex too."
    }

    func performPrimaryIconAction(for entry: SkillCatalogEntry) {
        switch iconPrimaryAction(for: entry) {
        case .useDefaultIcon:
            clearMenuBarEntry()
        case .installPinnedSkill, .installAndPin:
            installAndPin(entry)
        case .pinToMenuBar:
            setMenuBarEntry(entry)
        }
    }

    func performCatalogRowAccessoryAction(for entry: SkillCatalogEntry) {
        switch catalogRowAccessoryAction(for: entry) {
        case .useDefaultIcon:
            clearMenuBarEntry()
        case .installPinnedSkill:
            installAndPin(entry)
        case .pinToMenuBar:
            setMenuBarEntry(entry)
        case .installAndPin:
            installAndPin(entry)
        }
    }

    func clearMenuBarEntry() {
        menuBarSkillID = nil
        storeMenuBarSnapshot(nil)
        statusHeadline = "SkillBar icon reset"
        statusDetail = "The menu bar icon is back to the default SkillBar stack. Pick any skill from Icons to pin it again."
    }

    func installAndPin(_ entry: SkillCatalogEntry) {
        let previousMenuBarSkillID = menuBarSkillID
        run(
            request: SkillCommandRequest(
                action: .install,
                skillIDs: [entry.id],
                repoRootPath: repoRootPath ?? "",
                destinationPath: installedSkillsPath
            ),
            label: "Install + Pin \(entry.displayName)",
            successDetail: "\(entry.displayName) is installed and pinned to the SkillBar menu bar.",
            onSuccess: { [weak self] in
                self?.persistMenuBarSelection(for: entry)
            },
            onFailure: { [weak self] in
                self?.menuBarSkillID = previousMenuBarSkillID
            }
        )
    }

    func cancelPresetRequest() {
        pendingPreset = nil
    }

    func enablePendingPreset() {
        guard let preset = pendingPreset else { return }
        pendingPreset = nil
        let installable = installablePresetSkillIDs(for: preset)
        let missing = missingPresetSkillIDs(for: preset)
        guard !installable.isEmpty else {
            statusHeadline = "\(preset.title) has no available skills"
            statusDetail = missing.isEmpty
                ? "This preset does not map to any installable skills in the current repo."
                : "Missing from the current repo: \(missing.joined(separator: ", "))."
            return
        }
        run(request: SkillCommandRequest(
            action: .install,
            skillIDs: installable,
            repoRootPath: repoRootPath ?? "",
            destinationPath: installedSkillsPath
        ), label: "Enable \(preset.title)", successDetail: presetSuccessDetail(title: preset.title, installable: installable, missing: missing))
    }

    private func run(
        request: SkillCommandRequest,
        label: String,
        successDetail: String? = nil,
        onSuccess: (() -> Void)? = nil,
        onFailure: (() -> Void)? = nil
    ) {
        guard !isBusy else {
            statusHeadline = activeCommandLabel ?? "SkillBar is busy"
            statusDetail = "Wait for the current command to finish before starting another install, update, audit, or development loop."
            return
        }

        guard hasValidRepo else {
            statusHeadline = "Repo path missing"
            statusDetail = "Choose a local clone with `skills/` and `bin/codex-goated` first."
            selectedSection = .setup
            return
        }

        isBusy = true
        activeCommandLabel = label
        activePackID = request.packID
        activeSkillIDs = Set(request.skillIDs)
        statusHeadline = label
        statusDetail = "Running through codex-goated..."

        Task {
            do {
                if request.action.includesDestinationPath {
                    try ensureInstalledSkillsFolderExists()
                }
                let result = try await runCommand(request)
                lastCommandOutput = result.output
                refreshCatalog()
                onSuccess?()
                statusHeadline = "\(label) complete"
                let trimmedOutput = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                statusDetail = successDetail ?? (trimmedOutput.isEmpty
                    ? "SkillBar finished without extra output."
                    : trimmedOutput)
            } catch {
                onFailure?()
                lastCommandOutput = error.localizedDescription
                statusHeadline = "\(label) failed"
                statusDetail = error.localizedDescription
            }
            activePackID = nil
            activeSkillIDs = []
            activeCommandLabel = nil
            isBusy = false
        }
    }

    func presetEntries(_ preset: SkillPreset) -> [SkillCatalogEntry] {
        preset.includedSkillIDs.compactMap { id in entries.first(where: { $0.id == id }) }
    }

    func installablePresetSkillIDs(for preset: SkillPreset) -> [String] {
        presetEntries(preset).map(\.id)
    }

    func missingPresetSkillIDs(for preset: SkillPreset) -> [String] {
        let available = Set(installablePresetSkillIDs(for: preset))
        return preset.includedSkillIDs.filter { !available.contains($0) }
    }

    func packMembers(for pack: SkillPackEntry) -> [SkillCatalogEntry] {
        pack.includedSkillIDs.compactMap { id in entries.first(where: { $0.id == id }) }
    }

    func packAvailabilitySummary(for pack: SkillPackEntry) -> String? {
        let availableCount = packMembers(for: pack).count

        if pack.includedSkillIDs.isEmpty {
            return "No bundled skills declared."
        }

        guard pack.hasUnresolvedMembers else {
            if availableCount == 0 {
                return "\(pack.includedSkillIDs.count) bundled skills"
            }
            return nil
        }

        if availableCount == 0 {
            return "0 of \(pack.includedSkillIDs.count) bundled skills are available in this repo."
        }

        return "\(availableCount) of \(pack.includedSkillIDs.count) bundled skills are available in this repo."
    }

    private func runRepoHealthAction(action: SkillCommandAction, label: String) {
        run(request: SkillCommandRequest(
            action: action,
            skillIDs: [],
            packID: nil,
            repoRootPath: repoRootPath ?? "",
            destinationPath: installedSkillsPath
        ), label: label)
    }

    private func useRepoRoot(_ path: String, selectionMode: RepoSelectionMode = .manual) {
        let resolvedPath = catalogService.normalizedRepoRoot(startingAt: path) ?? path
        repoRootPath = resolvedPath
        repoRootSelectionContext = Self.repoRootSelectionContext(
            requestedPath: path,
            resolvedPath: resolvedPath,
            fallbackPath: nil,
            selectionMode: selectionMode
        )
        defaults.set(resolvedPath, forKey: DefaultsKey.repoRootPath)
        refreshCatalog()
    }

    private func shouldSwitchQuickSetupRepo(to path: String) -> Bool {
        let normalizedTarget = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL.path
        guard let repoRootPath else { return true }
        let normalizedCurrent = URL(fileURLWithPath: repoRootPath, isDirectory: true).standardizedFileURL.path
        return normalizedCurrent != normalizedTarget || !hasValidRepo
    }

    private func refreshRepoSuggestions() {
        var candidates = catalogService.suggestedRepoRoots()
        if let repoRootPath {
            let standardized = URL(fileURLWithPath: repoRootPath, isDirectory: true).standardizedFileURL.path
            candidates.removeAll { $0 == standardized }
            candidates.insert(standardized, at: 0)
        }
        suggestedRepoRoots = candidates
    }

    private func reconcilePackFocus() {
        guard let focusedPackID else { return }
        guard let matchingPack = packEntries.first(where: { $0.id == focusedPackID }) else {
            resetPackFocus()
            return
        }

        focusedPackTitle = matchingPack.title
        focusedSkillIDs = resolvedPackSkillIDs(for: matchingPack)
    }

    private func resetPackFocus() {
        focusedPackID = nil
        focusedPackTitle = nil
        focusedSkillIDs = []
    }

    private func persistMenuBarSelection(for entry: SkillCatalogEntry) {
        menuBarSkillID = entry.id
        storeMenuBarSnapshot(entry.menuBarSnapshot)
    }

    private func storeMenuBarSnapshot(_ snapshot: PinnedMenuBarEntrySnapshot?) {
        menuBarSnapshot = snapshot
        if let snapshot,
           let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: DefaultsKey.menuBarSnapshot)
        } else {
            defaults.removeObject(forKey: DefaultsKey.menuBarSnapshot)
        }
    }

    private static func loadMenuBarSnapshot(from defaults: UserDefaults) -> PinnedMenuBarEntrySnapshot? {
        guard let data = defaults.data(forKey: DefaultsKey.menuBarSnapshot) else {
            return nil
        }
        return try? JSONDecoder().decode(PinnedMenuBarEntrySnapshot.self, from: data)
    }

    private func ensureInstalledSkillsFolderExists() throws {
        let folderURL = URL(fileURLWithPath: installedSkillsPath, isDirectory: true)
        if FileManager.default.fileExists(atPath: folderURL.path), !directoryExists(at: folderURL.path) {
            throw NSError(
                domain: "SkillBarModel",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "\(installedSkillsDisplayPath) already exists as a file, so SkillBar cannot use it as the installs folder."]
            )
        }
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
    }

    private func directoryExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private func presetSuccessDetail(title: String, installable: [String], missing: [String]) -> String {
        let installedSummary = "Installed or refreshed \(installable.joined(separator: ", "))."
        guard !missing.isEmpty else {
            return installedSummary
        }
        return "\(installedSummary) Missing from the current repo: \(missing.joined(separator: ", "))."
    }

    private func updateCatalogReadyStatus() {
        if let focusedPackID,
           let matchingPack = packEntries.first(where: { $0.id == focusedPackID }) {
            let visibleCount = resolvedPackSkillIDs(for: matchingPack).count
            statusHeadline = "Browsing \(matchingPack.title)"
            statusDetail = packFocusStatusDetail(for: matchingPack, visibleCount: visibleCount)
            return
        }

        statusHeadline = "Catalog ready"
        statusDetail = "\(entries.count) skills and \(packEntries.count) packs found, \(installedCount) skills installed, \(installedPackCount) packs ready."
    }

    private func resolvedPackSkillIDs(for pack: SkillPackEntry) -> Set<String> {
        let availableIDs = Set(entries.map(\.id))
        return Set(pack.includedSkillIDs.filter { availableIDs.contains($0) })
    }

    private func packFocusStatusDetail(for pack: SkillPackEntry, visibleCount: Int? = nil) -> String {
        let visibleCount = visibleCount ?? resolvedPackSkillIDs(for: pack).count
        let visibleLabel = visibleCount == 1 ? "1 available skill" : "\(visibleCount) available skills"

        guard pack.hasUnresolvedMembers else {
            return "Showing \(visibleCount) bundled skills from this pack in the catalog."
        }

        let missingReferences = pack.unresolvedSkillIDs.joined(separator: ", ")
        if visibleCount > 0 {
            return "Showing \(visibleLabel) from this pack. Missing from this repo: \(missingReferences)."
        }

        return "This pack has no available skills in the current repo. Missing from this repo: \(missingReferences)."
    }

    static let defaultPresets: [SkillPreset] = [
        SkillPreset(id: "telegram-ops", title: "Telegram Ops", summary: "TeleBar plus Context Assembly for operator handoff, thread drafting, and escalation packs.", includedSkillIDs: ["telebar", "clipboard-studio"]),
        SkillPreset(id: "network-sentinel", title: "Network Sentinel", summary: "Local network monitoring plus Telegram delivery for cleaner alerting and operator follow-up.", includedSkillIDs: ["network-studio", "telebar"]),
        SkillPreset(id: "field-desk", title: "Field Desk", summary: "Phone recovery and field coordination flows that pair provider-aware handoffs with Telegram control.", includedSkillIDs: ["find-my-phone-studio", "telebar"]),
        SkillPreset(id: "launch-kit", title: "Launch Kit", summary: "The core go-to set for turning a rough project into a polished, publishable package.", includedSkillIDs: ["repo-launch", "content-pack", "brand-kit"]),
        SkillPreset(id: "utility-builder", title: "Utility Builder", summary: "A focused tool-making bundle for productivity, monitoring, and Mac utility workflows.", includedSkillIDs: ["clipboard-studio", "network-studio", "find-my-phone-studio"])
    ]

    nonisolated static func abbreviatedPath(_ path: String?) -> String? {
        guard let path, !path.isEmpty else { return nil }
        return NSString(string: path).abbreviatingWithTildeInPath
    }

    nonisolated static func displayName(for path: String?) -> String? {
        guard let path, !path.isEmpty else { return nil }
        let name = URL(fileURLWithPath: path, isDirectory: true).lastPathComponent
        return name.isEmpty ? path : name
    }

    func repoShortcutLabel(for path: String, actionPrefix: String = "Use") -> String {
        Self.repoShortcutLabel(for: path, among: repoLabelCandidates, actionPrefix: actionPrefix)
    }

    func quickSetupRepoActionLabel(actionPrefix: String) -> String {
        if quickSetupUsesCurrentRepoSelection {
            return "\(actionPrefix) Current Repo"
        }
        return "\(actionPrefix) Detected Repo"
    }

    var quickSetupPrimaryActionLabel: String {
        primaryRepoActionLabel(
            usesCurrentSelection: quickSetupUsesCurrentRepoSelection,
            installsFolderExists: installedSkillsFolderExists
        )
    }

    var packRecoveryPrimaryActionLabel: String {
        primaryRepoActionLabel(
            usesCurrentSelection: packRecoveryUsesCurrentRepoSelection,
            installsFolderExists: installedSkillsFolderExists
        )
    }

    var setupRepoShortcutPath: String? {
        preferredDetectedRepoRoot
    }

    var hasSetupRepoShortcut: Bool {
        setupRepoShortcutPath != nil
    }

    var setupRepoShortcutLabel: String {
        guard let setupRepoShortcutPath else { return "Use Detected Repo" }
        return repoShortcutLabel(for: setupRepoShortcutPath)
    }

    var shouldOfferDefaultInstallsShortcut: Bool {
        !usesDefaultInstalledSkillsPath
    }

    var quickSetupStatusLabel: String {
        if let candidate = preferredDetectedRepoRoot {
            return Self.displayName(for: candidate) ?? "detected repo"
        }

        if !hasValidRepo {
            return "needs repo"
        }

        if !installedSkillsFolderExists {
            return "create installs"
        }

        if !usesDefaultInstalledSkillsPath {
            return "custom folder"
        }

        return "ready"
    }

    func packRecoveryRepoActionLabel(actionPrefix: String) -> String {
        if packRecoveryUsesCurrentRepoSelection {
            return "\(actionPrefix) Current Repo"
        }
        return "\(actionPrefix) Detected Repo"
    }

    private func primaryRepoActionLabel(usesCurrentSelection: Bool, installsFolderExists: Bool) -> String {
        if usesCurrentSelection {
            return installsFolderExists ? "Use Current Repo" : "Use Current Repo + Create Folder"
        }

        return installsFolderExists ? "Use Detected Repo" : "Use Detected Repo + Create Folder"
    }

    func menuBarRecoveryRepoActionLabel(actionPrefix: String) -> String {
        "\(actionPrefix) Detected Repo"
    }

    nonisolated static func repoShortcutLabel(for path: String, among candidates: [String], actionPrefix: String = "Use") -> String {
        let normalizedPath = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL.path
        let url = URL(fileURLWithPath: normalizedPath, isDirectory: true)
        let basename = url.lastPathComponent
        guard !basename.isEmpty else {
            return actionPrefix
        }

        let displayLabel = repoShortcutDisplayLabel(for: normalizedPath, among: normalizedUniquePaths(candidates))
        return "\(actionPrefix) \(displayLabel)"
    }

    private nonisolated static func normalizedUniquePaths(_ paths: [String]) -> [String] {
        var seen: Set<String> = []
        return paths
            .map { URL(fileURLWithPath: $0, isDirectory: true).standardizedFileURL.path }
            .filter { seen.insert($0).inserted }
    }

    private nonisolated static func repoShortcutDisplayLabel(for path: String, among candidates: [String]) -> String {
        let basename = URL(fileURLWithPath: path, isDirectory: true).lastPathComponent
        guard !basename.isEmpty else {
            return abbreviatedPath(path) ?? path
        }

        let matchingCandidates = candidates.filter {
            URL(fileURLWithPath: $0, isDirectory: true).lastPathComponent.caseInsensitiveCompare(basename) == .orderedSame
        }

        guard matchingCandidates.count > 1 else {
            return basename
        }

        let targetAncestors = repoShortcutAncestorComponents(for: path)
        let candidateAncestors = matchingCandidates.map { repoShortcutAncestorComponents(for: $0) }
        let maxDepth = candidateAncestors.map(\.count).max() ?? 0

        for depth in 1...maxDepth {
            let label = repoShortcutDisplayLabel(basename: basename, ancestors: targetAncestors, depth: depth)
            let duplicateCount = candidateAncestors.reduce(into: 0) { count, ancestors in
                if repoShortcutDisplayLabel(basename: basename, ancestors: ancestors, depth: depth)
                    .localizedCaseInsensitiveCompare(label) == .orderedSame {
                    count += 1
                }
            }

            if duplicateCount == 1 {
                return label
            }
        }

        return abbreviatedPath(path) ?? path
    }

    private nonisolated static func repoShortcutAncestorComponents(for path: String) -> [String] {
        let components = URL(fileURLWithPath: path, isDirectory: true)
            .standardizedFileURL
            .pathComponents
            .filter { $0 != "/" }
        guard !components.isEmpty else { return [] }
        return Array(components.dropLast().reversed())
    }

    private nonisolated static func repoShortcutDisplayLabel(basename: String, ancestors: [String], depth: Int) -> String {
        let prefix = ancestors.prefix(depth).reversed()
        let visibleComponents = Array(prefix) + [basename]
        return visibleComponents.joined(separator: "/")
    }

    private enum RepoSelectionMode {
        case restored
        case manual
        case detected
    }

    private nonisolated static func repoRootSelectionContext(
        requestedPath: String?,
        resolvedPath: String?,
        fallbackPath: String?,
        selectionMode: RepoSelectionMode
    ) -> RepoRootSelectionContext? {
        guard let resolvedPath else { return nil }

        let normalizedResolvedPath = URL(fileURLWithPath: resolvedPath, isDirectory: true).standardizedFileURL.path
        let normalizedRequestedPath = requestedPath.map { URL(fileURLWithPath: $0, isDirectory: true).standardizedFileURL.path }
        let normalizedFallbackPath = fallbackPath.map { URL(fileURLWithPath: $0, isDirectory: true).standardizedFileURL.path }

        if let normalizedRequestedPath, normalizedRequestedPath != normalizedResolvedPath {
            return RepoRootSelectionContext(
                badge: "Normalized",
                detail: "SkillBar started from the path you gave it and snapped to the nested repo clone that actually contains `skills/` and `bin/codex-goated`.",
                sourcePath: normalizedRequestedPath
            )
        }

        if let normalizedRequestedPath, normalizedRequestedPath == normalizedResolvedPath {
            switch selectionMode {
            case .restored:
                return RepoRootSelectionContext(
                    badge: "Saved",
                    detail: "SkillBar restored the repo clone you last used, so catalog and install actions stay pointed at the same checkout.",
                    sourcePath: nil
                )
            case .manual:
                return RepoRootSelectionContext(
                    badge: "Chosen",
                    detail: "This repo was chosen directly, so SkillBar will keep using it until you switch to another detected clone or pick a new folder.",
                    sourcePath: nil
                )
            case .detected:
                return RepoRootSelectionContext(
                    badge: "Detected",
                    detail: "This repo came from SkillBar’s local clone scan, which prioritizes cleaner canonical checkouts over publish or tmp copies.",
                    sourcePath: nil
                )
            }
        }

        if let normalizedFallbackPath, normalizedFallbackPath == normalizedResolvedPath {
            return RepoRootSelectionContext(
                badge: "Auto",
                detail: "SkillBar auto-selected the best local clone it could find because no saved repo path was available.",
                sourcePath: nil
            )
        }

        return RepoRootSelectionContext(
            badge: "Active",
            detail: "SkillBar is using this repo clone for catalog parsing, pack browsing, and install or update commands.",
            sourcePath: nil
        )
    }
}
