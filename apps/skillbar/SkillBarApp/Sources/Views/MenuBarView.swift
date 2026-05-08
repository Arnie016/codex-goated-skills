import AppKit
import SwiftUI

private enum SkillBarPalette {
    static let backgroundTop = Color(red: 0.075, green: 0.085, blue: 0.10)
    static let backgroundBottom = Color(red: 0.055, green: 0.060, blue: 0.075)
    static let surface = Color(red: 0.105, green: 0.115, blue: 0.140).opacity(0.98)
    static let raised = Color(red: 0.135, green: 0.145, blue: 0.175).opacity(0.98)
    static let border = Color.white.opacity(0.09)
    static let separator = Color.white.opacity(0.08)
    static let primaryText = Color.white.opacity(0.97)
    static let secondaryText = Color.white.opacity(0.78)
    static let mutedText = Color.white.opacity(0.54)
    static let accent = Color(red: 0.54, green: 0.82, blue: 1.0)
    static let accentSoft = Color(red: 0.35, green: 0.67, blue: 1.0)
    static let installed = Color(red: 0.34, green: 0.82, blue: 0.63)
    static let warm = Color(red: 0.97, green: 0.74, blue: 0.36)
}

struct MenuBarView: View {
    @ObservedObject var model: SkillBarModel
    @State private var selectedIconID: String?
    @State private var hoveredIconID: String?

    private var hasCatalogRecoveryScope: Bool {
        model.hasActiveCatalogScope
    }

    private var iconEntries: [SkillCatalogEntry] {
        sortedIconEntries(model.filteredEntries)
    }

    private var iconEntryIDs: [String] {
        iconEntries.map(\.id)
    }

    private var catalogIconEntries: [SkillCatalogEntry] {
        sortedIconEntries(model.entries)
    }

    private var firstMissingCatalogIconEntry: SkillCatalogEntry? {
        catalogIconEntries.first { $0.iconSmallPath == nil && $0.iconLargePath == nil }
    }

    private var firstDuplicateCatalogIconEntry: SkillCatalogEntry? {
        let duplicateIDs = model.duplicateNameIDs(in: model.entries)
        guard !duplicateIDs.isEmpty else { return nil }
        return catalogIconEntries.first { duplicateIDs.contains($0.id) }
    }

    private var scopedMissingIconCount: Int {
        iconEntries.filter { $0.iconSmallPath == nil && $0.iconLargePath == nil }.count
    }

    private var scopedDuplicateIconCount: Int {
        model.duplicateNameCount(in: iconEntries)
    }

    private var firstMissingScopedIconEntry: SkillCatalogEntry? {
        iconEntries.first { $0.iconSmallPath == nil && $0.iconLargePath == nil }
    }

    private var firstDuplicateScopedIconEntry: SkillCatalogEntry? {
        let duplicateIDs = model.duplicateNameIDs(in: iconEntries)
        guard !duplicateIDs.isEmpty else { return nil }
        return iconEntries.first { duplicateIDs.contains($0.id) }
    }

    private var selectedIconEntry: SkillCatalogEntry? {
        if let selectedIconID,
           let entry = iconEntries.first(where: { $0.id == selectedIconID }) {
            return entry
        }

        return iconEntries.first
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SkillBarPalette.backgroundTop,
                    SkillBarPalette.accent.opacity(0.08),
                    SkillBarPalette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 0) {
                sidebar

                Divider()
                    .overlay(SkillBarPalette.separator)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                        controlPanel
                        content
                        footer
                    }
                    .padding(14)
                }
                .frame(width: 590, height: 680)
            }
            .frame(width: 750, height: 680)
        }
        .onAppear {
            syncSelectedIcon()
        }
        .onChange(of: iconEntryIDs) { _, _ in
            syncSelectedIcon()
        }
        .confirmationDialog(
            model.pendingPreset.map { "Enable \($0.title)?" } ?? "",
            isPresented: Binding(
                get: { model.pendingPreset != nil },
                set: { if !$0 { model.cancelPresetRequest() } }
            ),
            titleVisibility: .visible
        ) {
            Button("Enable Preset") {
                model.enablePendingPreset()
            }
            Button("Cancel", role: .cancel) {
                model.cancelPresetRequest()
            }
        } message: {
            if let preset = model.pendingPreset {
                Text("This will install or refresh \(preset.includedSkillIDs.joined(separator: ", ")).")
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(SkillBarPalette.accent)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(SkillBarPalette.accent.opacity(0.14))
                    )

                Text("SkillBar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SkillBarPalette.primaryText)
                Text("Manage what Codex can use.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 6) {
                ForEach(SkillBarSection.allCases) { section in
                    sidebarButton(section)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 7) {
                compactSidebarMetric("Skills", "\(model.availableCount)")
                compactSidebarMetric("Installed", "\(model.installedCount)")
                compactSidebarMetric("Packs", "\(model.packCount)")

                Button {
                    model.quitApp()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "power")
                            .font(.system(size: 12, weight: .bold))
                        Text("Quit")
                            .font(.caption.weight(.bold))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(SkillBarPalette.secondaryText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(SkillBarPalette.surface.opacity(0.74))
                    )
                }
                .buttonStyle(.plain)
                .help("Quit SkillBar.")
            }
        }
        .padding(12)
        .frame(width: 160, height: 680, alignment: .topLeading)
        .background(SkillBarPalette.backgroundBottom.opacity(0.72))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.selectedSection.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SkillBarPalette.primaryText)
                Text(model.statusHeadline)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(model.isBusy ? SkillBarPalette.accent : SkillBarPalette.secondaryText)
                    .lineLimit(1)
                Text(model.statusDetail)
                    .font(.caption2)
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .lineLimit(2)
            }

            Spacer()

            if model.isBusy {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 22, height: 22)
                    .help(model.activeCommandLabel ?? "Working")
            }

            statusChip("\(model.installedCount) installed", tint: SkillBarPalette.installed.opacity(0.18), foreground: SkillBarPalette.installed)

            Button {
                model.refreshCatalog()
            } label: {
                Image(systemName: model.isBusy ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SkillBarPalette.primaryText)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .disabled(model.isBusy)
            .help("Refresh the repo catalog and installed skill state.")
        }
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                compactMetric("Catalog", "\(model.availableCount)")
                compactMetric("Installed", "\(model.installedCount)")
                compactMetric("Packs", "\(model.packCount)")
                Spacer(minLength: 0)
                statusChip(
                    model.hasValidRepo ? "repo ready" : "pick repo",
                    tint: model.hasValidRepo ? SkillBarPalette.accent.opacity(0.18) : SkillBarPalette.warm.opacity(0.16),
                    foreground: model.hasValidRepo ? SkillBarPalette.accent : SkillBarPalette.warm
                )
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(SkillBarPalette.mutedText)
                TextField("Search skills, categories, and use cases", text: $model.searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(SkillBarPalette.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(groupedBackground())

            if model.hasActiveCatalogScope {
                activeCatalogScopePanel
            }

            currentMenuBarPanel
        }
    }

    private var activeCatalogScopePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Active View")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SkillBarPalette.secondaryText)

                Spacer(minLength: 0)

                if model.hasActiveCatalogScope {
                    Button("Reset View") {
                        resetCatalogRecoveryScope()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(model.isBusy)
                }

                if !activeCatalogScopeActions.isEmpty {
                    settingRowOptionsMenu(title: "Active View", actions: activeCatalogScopeActions)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                if let searchScopeTitle = Self.activeScopeChipTitle(prefix: "Search", value: model.searchText) {
                    activeScopeClearChip(
                        title: searchScopeTitle,
                        tint: SkillBarPalette.accent.opacity(0.18),
                        foreground: SkillBarPalette.accent,
                        clearHelp: "Clear the search filter."
                    ) {
                        model.clearSearch()
                    }
                }

                if let packScopeTitle = Self.activeScopeChipTitle(prefix: "Pack", value: model.focusedPackTitle) {
                    activeScopeClearChip(
                        title: packScopeTitle,
                        tint: SkillBarPalette.warm.opacity(0.16),
                        foreground: SkillBarPalette.warm,
                        clearHelp: "Clear the pack filter."
                    ) {
                        model.clearPackFocus()
                    }
                }
            }

            Text(activeCatalogScopeDetail)
                .font(.caption2)
                .foregroundStyle(SkillBarPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(groupedBackground())
    }

    private var activeCatalogScopeActions: [SettingRowAction] {
        var actions: [SettingRowAction] = []

        if model.hasSearchText {
            actions.append(.init(title: "Clear Search", isDisabled: model.isBusy) {
                model.clearSearch()
            })
        }

        if model.hasPackFocus {
            actions.append(.init(title: "Clear Pack", isDisabled: model.isBusy) {
                model.clearPackFocus()
            })
        }

        return actions
    }

    static func activeScopeChipTitle(prefix: String, value: String?, maxValueLength: Int = 28) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        let safeMaxValueLength = max(4, maxValueLength)
        let displayValue: String
        if trimmedValue.count > safeMaxValueLength {
            displayValue = String(trimmedValue.prefix(safeMaxValueLength - 3)) + "..."
        } else {
            displayValue = trimmedValue
        }

        return "\(prefix): \(displayValue)"
    }

    private var currentMenuBarPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Current Menu Bar Icon")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SkillBarPalette.secondaryText)
                Spacer(minLength: 0)
                statusChip(
                    model.hasPinnedMenuBarSelection ? "Pinned" : "Default",
                    tint: model.hasPinnedMenuBarSelection ? SkillBarPalette.accent.opacity(0.18) : SkillBarPalette.border,
                    foreground: model.hasPinnedMenuBarSelection ? SkillBarPalette.accent : SkillBarPalette.secondaryText
                )
            }

            HStack(alignment: .center, spacing: 10) {
                SkillBarMenuIcon(
                    isBusy: model.isBusy,
                    installedCount: model.installedCount,
                    entry: model.menuBarSelection
                )
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(SkillBarPalette.raised.opacity(0.55))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.menuBarSelectionDisplayName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SkillBarPalette.primaryText)
                        .lineLimit(1)
                    Text(model.menuBarRevealDetail)
                        .font(.caption2)
                        .foregroundStyle(model.hasUnavailablePinnedMenuBarSelection ? SkillBarPalette.warm : SkillBarPalette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                Button("Browse Icons") {
                    openFullIconBoard()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy || model.entries.isEmpty)
                .help("Open the full icon catalog and clear any search or pack filter.")

                if let recoveryEntry = model.menuBarInstallRecoveryEntry {
                    Button("Install Pinned Skill") {
                        model.performPrimaryIconAction(for: recoveryEntry)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isBusy || !model.hasValidRepo)
                    .help("Reinstall \(recoveryEntry.displayName) into the current skills folder and keep it pinned to the menu bar.")
                }

                if let pinnedEntry = model.menuBarEntry,
                   Self.shouldShowPinnedMenuBarUpdate(
                    hasPinnedSelection: model.hasPinnedMenuBarSelection,
                    canRevealPinnedEntry: model.canRevealPinnedMenuBarEntry,
                    isInstalled: pinnedEntry.isInstalled
                   ) {
                    Button {
                        model.runAction(for: pinnedEntry)
                    } label: {
                        actionButtonLabel(
                            title: model.isRunning(pinnedEntry) ? "Updating" : "Update Pinned",
                            isRunning: model.isRunning(pinnedEntry)
                        )
                    }
                    .buttonStyle(.bordered)
                    .disabled(Self.shouldDisableIconCLICommand(
                        isBusy: model.isBusy,
                        hasValidRepo: model.hasValidRepo
                    ))
                    .help("Update \(pinnedEntry.displayName) without changing the current menu bar icon.")
                }

                if Self.shouldShowPinnedTileButton(
                    hasPinnedSelection: model.hasPinnedMenuBarSelection,
                    canRevealPinnedEntry: model.canRevealPinnedMenuBarEntry
                ) {
                    Button(model.menuBarRevealButtonTitle) {
                        openCurrentPinnedIcon()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isBusy)
                    .help(model.menuBarRevealDetail)
                }

                if model.hasPinnedMenuBarSelection {
                    if model.hasMenuBarRecoveryRepoShortcut {
                        pinnedMenuBarRecoveryButton(compact: false)
                    }

                    pinnedMenuBarDefaultButton(compact: false)
                }

                Spacer(minLength: 0)
            }

            if let recoveryPath = model.menuBarRecoveryRepoDisplayPath {
                Text("Detected recovery repo: \(recoveryPath)")
                    .font(.caption2)
                    .foregroundStyle(SkillBarPalette.warm)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(groupedBackground())
    }

    private var sectionPicker: some View {
        Picker("Section", selection: $model.selectedSection) {
            ForEach(SkillBarSection.allCases) { section in
                Text(section.title).tag(section)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var content: some View {
        switch model.selectedSection {
        case .discover:
            VStack(alignment: .leading, spacing: 10) {
                presetsPanel
                groupedPanel {
                    sectionLabel("All Skills", trailing: "\(model.discoverEntries.count)")
                    if model.discoverEntries.isEmpty {
                        discoverEmptyState
                    } else {
                        ForEach(Array(model.discoverEntries.enumerated()), id: \.element.id) { index, entry in
                            if index > 0 { Divider().overlay(SkillBarPalette.separator) }
                            skillRow(entry)
                        }
                    }
                }
            }
        case .installed:
            groupedPanel {
                sectionLabel("Installed Skills", trailing: "\(model.installedEntries.count)")
                if model.installedEntries.isEmpty {
                    installedEmptyState
                } else {
                    ForEach(Array(model.installedEntries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 { Divider().overlay(SkillBarPalette.separator) }
                        skillRow(entry)
                    }
                }
            }
        case .icons:
            iconsPanel
        case .presets:
            presetsPanel
        case .packs:
            packsPanel
        case .setup:
            setupPanel
        }
    }

    private var presetsPanel: some View {
        groupedPanel {
            sectionLabel("Recommended Presets", trailing: "\(model.presets.count)")
            ForEach(Array(model.presets.enumerated()), id: \.element.id) { index, preset in
                if index > 0 { Divider().overlay(SkillBarPalette.separator) }
                presetRow(preset)
            }
        }
    }

    private var packsPanel: some View {
        groupedPanel {
            sectionLabel("Repo Packs", trailing: "\(model.filteredPackEntries.count)")
            if model.filteredPackEntries.isEmpty {
                packsEmptyState
            } else {
                ForEach(Array(model.filteredPackEntries.enumerated()), id: \.element.id) { index, pack in
                    if index > 0 { Divider().overlay(SkillBarPalette.separator) }
                    packRow(pack)
                }
            }
        }
    }

    private var setupPanel: some View {
        groupedPanel {
            sectionLabel("Setup", trailing: model.hasValidRepo ? "ready" : "needs path")

            quickSetupActions

            Divider().overlay(SkillBarPalette.separator)

            settingRow(
                title: "Repo Root",
                value: model.repoRootPath ?? "Not set",
                primaryActionTitle: "Choose",
                primaryAction: {
                    model.chooseRepoRoot()
                },
                secondaryActions: [
                    .init(title: "Open", isDisabled: model.isBusy || !model.hasRecoverableRepoRootSelection) {
                        model.openRepoRoot()
                    },
                    .init(title: "Reveal", isDisabled: model.isBusy || !model.hasRecoverableRepoRootSelection) {
                        model.revealRepoInFinder()
                    },
                    .init(title: model.setupRepoShortcutLabel, isDisabled: model.isBusy || !model.hasSetupRepoShortcut) {
                        guard let path = model.setupRepoShortcutPath else { return }
                        model.useSuggestedRepoRoot(path)
                    }
                ]
            )

            Divider().overlay(SkillBarPalette.separator)

            settingRow(
                title: "Installed Skills",
                value: model.installedSkillsPath,
                primaryActionTitle: "Choose",
                primaryAction: {
                    model.chooseInstalledSkillsFolder()
                },
                secondaryActions: [
                    .init(title: "Open", isDisabled: model.isBusy || !model.installedSkillsFolderExists) {
                        model.openInstalledSkillsFolder()
                    },
                    .init(title: "Reveal", isDisabled: model.isBusy || !model.installedSkillsFolderExists) {
                        model.revealInstalledSkillsFolder()
                    },
                    .init(title: "Use Default", isDisabled: model.isBusy || !model.shouldOfferDefaultInstallsShortcut) {
                        model.useDefaultInstalledSkillsFolder()
                    }
                ]
            )

            Divider().overlay(SkillBarPalette.separator)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Menu Bar Icons", trailing: "\(model.availableCount)")

                pinnedMenuBarStatusStrip(compact: false)

                HStack(spacing: 8) {
                    Button("Browse Icons") {
                        openFullIconBoard()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.entries.isEmpty)

                    if let recoveryEntry = model.menuBarInstallRecoveryEntry {
                        Button("Install Pinned Skill") {
                            model.performPrimaryIconAction(for: recoveryEntry)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isBusy || !model.hasValidRepo)
                        .help("Reinstall \(recoveryEntry.displayName) into the current skills folder and keep it pinned to the menu bar.")
                    }
                    Button("Refresh") {
                        model.refreshCatalog()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isBusy || !model.hasValidRepo)
                }

                Text("Browse every icon, jump straight back to the currently pinned tile when it exists in this repo, or reset the menu bar to the default SkillBar stack without hunting through the full grid.")
                    .font(.caption2)
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                if !model.canRevealPinnedMenuBarEntry {
                    Text(model.menuBarRevealDetail)
                        .font(.caption2)
                        .foregroundStyle(model.hasPinnedMenuBarSelection ? SkillBarPalette.warm : SkillBarPalette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let recoveryPath = model.menuBarRecoveryRepoDisplayPath {
                    Text("Detected recovery repo: \(recoveryPath)")
                        .font(.caption2)
                        .foregroundStyle(SkillBarPalette.warm)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider().overlay(SkillBarPalette.separator)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Catalog Guardrails", trailing: model.catalogQualityLabel)

                HStack(spacing: 6) {
                    guardrailShortcutChip(
                        title: "\(model.missingIconCount) missing icons",
                        tint: model.missingIconCount == 0 ? SkillBarPalette.installed.opacity(0.18) : SkillBarPalette.warm.opacity(0.16),
                        foreground: model.missingIconCount == 0 ? SkillBarPalette.installed : SkillBarPalette.warm,
                        isInteractive: model.missingIconCount > 0,
                        action: revealMissingCatalogIcons
                    )
                    guardrailShortcutChip(
                        title: "\(model.duplicateNameCount) repeats",
                        tint: model.duplicateNameCount == 0 ? SkillBarPalette.installed.opacity(0.18) : SkillBarPalette.warm.opacity(0.16),
                        foreground: model.duplicateNameCount == 0 ? SkillBarPalette.installed : SkillBarPalette.warm,
                        isInteractive: model.duplicateNameCount > 0,
                        action: revealDuplicateCatalogIcons
                    )
                }

                Text("SkillBar installs from the selected local repo into the selected skills folder; audit before shipping changes, and preserve existing menu bar apps.")
                    .font(.caption2)
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                if model.missingIconCount > 0 || model.duplicateNameCount > 0 {
                    Text("Select a warm guardrail chip to jump straight into icon cleanup.")
                        .font(.caption2)
                        .foregroundStyle(SkillBarPalette.warm)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider().overlay(SkillBarPalette.separator)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Repo Health", trailing: model.hasValidRepo ? "ready" : "needs repo")

                HStack(spacing: 8) {
                    Button("Dev Loop") {
                        model.runDevelopmentLoop()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isBusy || !model.hasValidRepo)
                    .help("Run codex-goated develop against the selected repo clone.")

                    Button("Catalog Check") {
                        model.runCatalogCheck()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isBusy || !model.hasValidRepo)
                    .help("Run codex-goated catalog check against the selected repo clone.")

                    Button("Audit") {
                        model.runAudit()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isBusy || !model.hasValidRepo)
                    .help("Run codex-goated audit against the selected repo clone.")

                    Spacer(minLength: 0)
                }

                Text("Run the repo development loop, check catalog freshness, and audit repo integrity from inside SkillBar instead of switching to the shell.")
                    .font(.caption2)
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if model.hasRecentCommandOutput {
                Divider().overlay(SkillBarPalette.separator)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Recent Command Output")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SkillBarPalette.secondaryText)

                    Spacer(minLength: 0)

                    Button("Copy") {
                        copyRecentCommandOutputToPasteboard()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Copy the recent command output to the clipboard.")

                    Button("Clear") {
                        model.clearCommandOutput()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(model.isBusy)
                }
                Text(model.lastCommandOutput)
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(SkillBarPalette.primaryText)
                    .lineLimit(10)
            }
        }
    }

    @ViewBuilder
    private var quickSetupActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Quick Setup", trailing: setupQuickActionStatus)

            Text("Use the fastest local-first path to get SkillBar pointed at the right repo clone and a writable installs folder.")
                .font(.caption2)
                .foregroundStyle(SkillBarPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if model.quickSetupRepoRoot != nil {
                    Button(model.quickSetupPrimaryActionLabel) {
                        model.completeQuickSetup()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isBusy)
                    .help(model.quickSetupUsesCurrentRepoSelection
                        ? "Keep the active repo selection and make sure the installs folder exists."
                        : "Adopt this detected repo clone and make sure the installs folder exists.")
                }

                if Self.shouldShowQuickSetupDirectCreateFolder(
                    folderExists: model.installedSkillsFolderExists
                ) {
                    quickSetupCreateFolderButton(prominent: model.quickSetupRepoRoot == nil)
                }

                quickSetupFolderOptionsMenu()

                Spacer(minLength: 0)
            }

            if let candidate = model.quickSetupRepoRoot {
                HStack(spacing: 6) {
                    statusChip(
                        model.quickSetupUsesCurrentRepoSelection ? "Current repo" : "Detected repo",
                        tint: model.quickSetupUsesCurrentRepoSelection ? SkillBarPalette.accent.opacity(0.18) : SkillBarPalette.warm.opacity(0.16),
                        foreground: model.quickSetupUsesCurrentRepoSelection ? SkillBarPalette.accent : SkillBarPalette.warm
                    )
                    Text(SkillBarModel.abbreviatedPath(candidate) ?? candidate)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SkillBarPalette.secondaryText)
                        .lineLimit(1)
                }
            } else if let staleRepoSelectionDetail = model.staleRepoSelectionDetail {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SkillBarPalette.warm)
                        .padding(.top, 2)

                    Text(staleRepoSelectionDetail)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SkillBarPalette.warm)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                Button("Choose Repo") {
                    model.chooseRepoRoot()
                }
                .buttonStyle(.bordered)
                .disabled(model.isBusy)

                if model.canAccessQuickSetupRepoRoot {
                    quickSetupRepoOptionsMenu()
                }

                Spacer(minLength: 0)
            }
        }
    }

    static func shouldShowQuickSetupDirectCreateFolder(folderExists: Bool) -> Bool {
        !folderExists
    }

    @ViewBuilder
    private func quickSetupCreateFolderButton(prominent: Bool) -> some View {
        if prominent {
            Button("Create Folder") {
                model.createInstalledSkillsFolderIfNeeded()
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isBusy)
            .help("Create the installs folder at \(SkillBarModel.abbreviatedPath(model.installedSkillsPath) ?? model.installedSkillsPath).")
        } else {
            Button("Create Folder") {
                model.createInstalledSkillsFolderIfNeeded()
            }
            .buttonStyle(.bordered)
            .disabled(model.isBusy)
            .help("Create only the installs folder at \(SkillBarModel.abbreviatedPath(model.installedSkillsPath) ?? model.installedSkillsPath) without changing the selected repo.")
        }
    }

    private var quickSetupFolderActions: [SettingRowAction] {
        var actions: [SettingRowAction] = []

        if model.installedSkillsFolderExists {
            actions.append(.init(title: "Open Folder", isDisabled: model.isBusy) {
                model.openInstalledSkillsFolder()
            })
            actions.append(.init(title: "Reveal Folder", isDisabled: model.isBusy) {
                model.revealInstalledSkillsFolder()
            })
        }

        if !model.usesDefaultInstalledSkillsPath {
            actions.append(.init(title: "Use Default", isDisabled: model.isBusy) {
                model.useDefaultInstalledSkillsFolder()
            })
        }

        actions.append(.init(title: "Choose Folder", isDisabled: model.isBusy) {
            model.chooseInstalledSkillsFolder()
        })

        return actions
    }

    private var quickSetupRepoActions: [SettingRowAction] {
        guard model.canAccessQuickSetupRepoRoot else { return [] }
        return [
            .init(title: model.quickSetupRepoActionLabel(actionPrefix: "Open"), isDisabled: model.isBusy) {
                model.openQuickSetupRepoRoot()
            },
            .init(title: model.quickSetupRepoActionLabel(actionPrefix: "Reveal"), isDisabled: model.isBusy) {
                model.revealQuickSetupRepoRootInFinder()
            }
        ]
    }

    private func quickSetupFolderOptionsMenu() -> some View {
        settingRowOptionsMenu(title: "Installed Skills", actions: quickSetupFolderActions)
            .help("Open, reveal, reset, or choose the installs folder without changing the primary setup path.")
    }

    private func quickSetupRepoOptionsMenu() -> some View {
        settingRowOptionsMenu(title: "Repo Root", actions: quickSetupRepoActions)
            .help(model.quickSetupUsesCurrentRepoSelection
                ? "Inspect the active repo clone in Finder without changing setup."
                : "Inspect the detected repo clone before adopting it for SkillBar.")
    }

    private var iconsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            iconSettingsHeader

            if iconEntries.isEmpty {
                groupedPanel {
                    iconsEmptyState
                }
            } else {
                if let entry = selectedIconEntry {
                    selectedIconDetail(entry)
                }

                iconSettingsGrid
            }
        }
    }

    private var iconSettingsHeader: some View {
        groupedPanel {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(SkillBarPalette.accent)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(SkillBarPalette.accent.opacity(0.14))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        sectionLabel("Skill Icon Settings", trailing: "\(iconEntries.count)")
                        Spacer(minLength: 0)

                        if hasCatalogRecoveryScope {
                            Button("Reset View") {
                                openFullIconBoard()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(model.isBusy)
                        }
                    }
                    Text("A local settings board for the \(model.availableCount)-skill catalog: each tile is an app-like icon you can inspect and manage without opening GitHub.")
                        .font(.caption)
                        .foregroundStyle(SkillBarPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    if hasCatalogRecoveryScope {
                        Text(iconScopeStatusMessage)
                            .font(.caption2)
                            .foregroundStyle(SkillBarPalette.warm)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 6) {
                        statusChip(
                            "\(model.installedCount) installed",
                            tint: SkillBarPalette.installed.opacity(0.18),
                            foreground: SkillBarPalette.installed
                        )
                        guardrailShortcutChip(
                            title: "\(scopedMissingIconCount) missing icons",
                            tint: scopedMissingIconCount == 0 ? SkillBarPalette.installed.opacity(0.18) : SkillBarPalette.warm.opacity(0.16),
                            foreground: scopedMissingIconCount == 0 ? SkillBarPalette.installed : SkillBarPalette.warm,
                            isInteractive: scopedMissingIconCount > 0,
                            action: revealMissingIconsInCurrentScope
                        )
                        guardrailShortcutChip(
                            title: "\(scopedDuplicateIconCount) repeats",
                            tint: scopedDuplicateIconCount == 0 ? SkillBarPalette.installed.opacity(0.18) : SkillBarPalette.warm.opacity(0.16),
                            foreground: scopedDuplicateIconCount == 0 ? SkillBarPalette.installed : SkillBarPalette.warm,
                            isInteractive: scopedDuplicateIconCount > 0,
                            action: revealDuplicateIconsInCurrentScope
                        )
                    }

                    if scopedMissingIconCount > 0 || scopedDuplicateIconCount > 0 {
                        Text(hasCatalogRecoveryScope
                            ? "Warm chips jump to the first visible icon issue without clearing the current board scope."
                            : "Warm chips jump straight to the first icon issue in the full catalog.")
                            .font(.caption2)
                            .foregroundStyle(SkillBarPalette.warm)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    pinnedMenuBarStatusStrip(compact: true)
                }
            }
        }
    }

    private var iconSettingsGrid: some View {
        groupedPanel {
            sectionLabel(
                Self.iconGridTitle(
                    hasSearchText: model.hasSearchText,
                    hasPackFocus: model.hasPackFocus
                ),
                trailing: "\(iconEntries.count)"
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 92, maximum: 112), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(iconEntries) { entry in
                    iconTile(entry)
                }
            }
        }
    }

    private var footer: some View {
        Text("SkillBar reads your local codex-goated-skills repo and manages what is installed in ~/.codex/skills. Presets stay app-owned, while repo packs mirror collections and bundle existing skills; they do not own secrets or tokens.")
            .font(.caption2)
            .foregroundStyle(SkillBarPalette.mutedText)
            .padding(.horizontal, 4)
    }

    private func presetRow(_ preset: SkillPreset) -> some View {
        let members = model.presetEntries(preset)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SkillBarPalette.accent)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(SkillBarPalette.accent.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(preset.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(SkillBarPalette.primaryText)
                        Spacer()
                        Button("Enable Preset") {
                            model.requestPresetEnable(preset)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isBusy || !model.hasValidRepo)
                    }

                    Text(preset.summary)
                        .font(.caption)
                        .foregroundStyle(SkillBarPalette.secondaryText)

                    Text(members.map(\.displayName).joined(separator: " • "))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SkillBarPalette.mutedText)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func packRow(_ pack: SkillPackEntry) -> some View {
        let members = model.packMembers(for: pack)
        let availabilitySummary = model.packAvailabilitySummary(for: pack)
        let isRunning = model.isRunning(pack)
        let isFocused = model.isFocused(pack)
        let canOpenFocusedCatalog = model.canOpenFocusedPackCatalog(pack)
        let shouldPromoteBrowseAction = Self.shouldPromotePackBrowseAction(
            canRunInstallAction: pack.canRunInstallAction,
            isComplete: pack.isComplete,
            isFocused: isFocused
        )
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SkillBarPalette.accentSoft)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(SkillBarPalette.accentSoft.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(pack.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(SkillBarPalette.primaryText)
                        statusChip(
                            pack.statusLabel,
                            tint: pack.isComplete ? SkillBarPalette.installed.opacity(0.18) : SkillBarPalette.warm.opacity(0.16),
                            foreground: pack.isComplete ? SkillBarPalette.installed : SkillBarPalette.warm
                        )
                        if isFocused {
                            statusChip(
                                "In Catalog",
                                tint: SkillBarPalette.accent.opacity(0.18),
                                foreground: SkillBarPalette.accent
                            )
                        }
                        if isRunning {
                            statusChip(
                                "Running",
                                tint: SkillBarPalette.accent.opacity(0.18),
                                foreground: SkillBarPalette.accent
                            )
                        }
                    }

                    Text(pack.primaryDescription)
                        .font(.caption)
                        .foregroundStyle(SkillBarPalette.secondaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if pack.canRunInstallAction {
                    if pack.isComplete {
                        Button {
                            model.runAction(for: pack)
                        } label: {
                            actionButtonLabel(
                                title: isRunning ? "Updating" : model.action(for: pack).buttonTitle,
                                isRunning: isRunning
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(model.isBusy || !model.hasValidRepo)
                    } else {
                        Button {
                            model.runAction(for: pack)
                        } label: {
                            actionButtonLabel(
                                title: isRunning ? "Installing" : model.action(for: pack).buttonTitle,
                                isRunning: isRunning
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(model.isBusy || !model.hasValidRepo)
                    }
                }

                if canOpenFocusedCatalog {
                    Button("Open Catalog") {
                        model.selectedSection = .discover
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(model.isBusy || !model.hasValidRepo)
                    .help("Jump back to the current pack-filtered catalog.")
                } else {
                    if shouldPromoteBrowseAction {
                        Button {
                            model.browsePack(pack)
                        } label: {
                            Text(pack.browseButtonTitle)
                                .font(.caption.weight(.bold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(model.isBusy || !model.hasValidRepo)
                        .help("Filter the catalog to this pack.")
                    } else {
                        Button {
                            model.browsePack(pack)
                        } label: {
                            Text(pack.browseButtonTitle)
                                .font(.caption.weight(.bold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(model.isBusy || !model.hasValidRepo)
                        .help("Filter the catalog to this pack.")
                    }
                }

                if !pack.hasNoAvailableMembers {
                    Button("Icons") {
                        model.browsePackIcons(pack)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(model.isBusy || !model.hasValidRepo)
                    .help("Open the icon board filtered to this pack.")
                }
            }

            if !members.isEmpty {
                Text(members.map(\.displayName).joined(separator: " • "))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .lineLimit(2)
            } else if let availabilitySummary {
                Text(availabilitySummary)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(pack.hasUnresolvedMembers ? SkillBarPalette.warm : SkillBarPalette.mutedText)
            }

            if pack.hasUnresolvedMembers {
                if !members.isEmpty, let availabilitySummary {
                    Text(availabilitySummary)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SkillBarPalette.warm)
                }

                Text("Missing from this repo: \(pack.unresolvedSkillIDs.joined(separator: " • "))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SkillBarPalette.warm)
                    .lineLimit(2)
            }

            if pack.hasNoAvailableMembers {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SkillBarPalette.warm)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(pack.recoverySummary)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(SkillBarPalette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        if let candidatePath = model.packRecoveryRepoDisplayPath {
                            HStack(spacing: 6) {
                                statusChip(
                                    "Detected repo",
                                    tint: SkillBarPalette.warm.opacity(0.16),
                                    foreground: SkillBarPalette.warm
                                )
                                Text(candidatePath)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(SkillBarPalette.secondaryText)
                                    .lineLimit(1)
                            }
                        }

                        HStack(spacing: 8) {
                            if model.hasPackRecoveryRepoShortcut {
                                Button(model.packRecoveryPrimaryActionLabel) {
                                    model.completePackRecoveryQuickSetup()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(model.isBusy)
                                .help("Switch SkillBar to the detected repo clone and rebuild the local catalog before retrying this pack.")
                            } else {
                                Button("Open Setup") {
                                    model.selectedSection = .setup
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(model.isBusy)
                            }

                            if model.hasPackRecoveryRepoShortcut || model.hasValidRepo {
                                packRecoveryRepoMenu()
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(SkillBarPalette.warm.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(SkillBarPalette.warm.opacity(0.22), lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 2)
    }

    private func skillRow(_ entry: SkillCatalogEntry) -> some View {
        let isRunning = model.isRunning(entry)
        let accessoryAction = model.catalogRowAccessoryAction(for: entry)
        let accessoryDisabled = Self.shouldDisableCatalogRowAccessoryAction(
            action: accessoryAction,
            isBusy: model.isBusy,
            hasValidRepo: model.hasValidRepo
        )
        let cliCommandDisabled = Self.shouldDisableIconCLICommand(
            isBusy: model.isBusy,
            hasValidRepo: model.hasValidRepo
        )
        let shouldShowCLIAction = Self.shouldShowCatalogRowCLIAction(
            isInstalled: entry.isInstalled,
            accessoryAction: accessoryAction
        )
        let isPinnedToMenuBar = model.menuBarSkillID == entry.id
        return HStack(alignment: .top, spacing: 10) {
            iconView(for: entry)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SkillBarPalette.primaryText)

                    statusChip(
                        entry.categoryLabel,
                        tint: SkillBarPalette.border,
                        foreground: SkillBarPalette.secondaryText
                    )

                    if isPinnedToMenuBar {
                        statusChip(
                            "Menu Bar",
                            tint: SkillBarPalette.accent.opacity(0.18),
                            foreground: SkillBarPalette.accent
                        )
                    }

                    Spacer()
                }

                Text(entry.primaryDescription)
                    .font(.caption)
                    .foregroundStyle(SkillBarPalette.secondaryText)
                    .lineLimit(2)

                HStack {
                    Text(entry.id)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SkillBarPalette.mutedText)
                    Spacer()
                    if Self.shouldPromoteCatalogRowAccessoryAction(action: accessoryAction) {
                        Button(accessoryAction.buttonTitle) {
                            model.performCatalogRowAccessoryAction(for: entry)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(accessoryDisabled)
                    } else {
                        Button(accessoryAction.buttonTitle) {
                            model.performCatalogRowAccessoryAction(for: entry)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(accessoryDisabled)
                    }

                    if shouldShowCLIAction && entry.isInstalled {
                        Button {
                            model.runAction(for: entry)
                        } label: {
                            actionButtonLabel(title: isRunning ? "Updating" : model.action(for: entry).buttonTitle, isRunning: isRunning)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(cliCommandDisabled)
                    } else if shouldShowCLIAction {
                        Button {
                            model.runAction(for: entry)
                        } label: {
                            actionButtonLabel(title: isRunning ? "Installing" : model.action(for: entry).buttonTitle, isRunning: isRunning)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(cliCommandDisabled)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func iconLibraryRow(_ entry: SkillCatalogEntry) -> some View {
        HStack(alignment: .center, spacing: 10) {
            iconView(for: entry)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SkillBarPalette.primaryText)
                        .lineLimit(1)

                    statusChip(
                        entry.isInstalled ? "Installed" : "Available",
                        tint: entry.isInstalled ? SkillBarPalette.installed.opacity(0.18) : SkillBarPalette.border,
                        foreground: entry.isInstalled ? SkillBarPalette.installed : SkillBarPalette.secondaryText
                    )
                }

                Text(iconSourceLabel(for: entry))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .lineLimit(1)

                Text(entry.categoryLabel)
                    .font(.caption2)
                    .foregroundStyle(SkillBarPalette.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if entry.isInstalled {
                Button(model.action(for: entry).buttonTitle) {
                    model.runAction(for: entry)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(model.isBusy || !model.hasValidRepo)
            } else {
                Button(model.action(for: entry).buttonTitle) {
                    model.runAction(for: entry)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(model.isBusy || !model.hasValidRepo)
            }
        }
        .padding(.vertical, 2)
    }

    private func iconTile(_ entry: SkillCatalogEntry) -> some View {
        let isSelected = selectedIconEntry?.id == entry.id
        let isHovered = hoveredIconID == entry.id
        let isRunning = model.isRunning(entry)
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                selectedIconID = entry.id
            }
        } label: {
            VStack(spacing: 7) {
                largeIconView(for: entry)

                Text(entry.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SkillBarPalette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 28, alignment: .top)

                Circle()
                    .fill(isRunning ? SkillBarPalette.accent : (entry.isInstalled ? SkillBarPalette.installed : SkillBarPalette.mutedText))
                    .frame(width: isRunning ? 7 : 5, height: isRunning ? 7 : 5)
            }
            .padding(9)
            .frame(width: 98, height: 112)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected || isHovered ? SkillBarPalette.accent.opacity(isSelected ? 0.16 : 0.10) : Color.white.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected || isHovered ? SkillBarPalette.accent.opacity(0.36) : SkillBarPalette.border, lineWidth: 1)
            )
            .overlay(
                Group {
                    if isRunning {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(SkillBarPalette.backgroundBottom.opacity(0.78))
                            )
                    }
                },
                alignment: .topTrailing
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredIconID = hovering ? entry.id : (hoveredIconID == entry.id ? nil : hoveredIconID)
        }
        .help(Self.iconTileHelpText(
            displayName: entry.displayName,
            statusLabel: entry.statusLabel,
            categoryLabel: entry.categoryLabel,
            primaryDescription: entry.primaryDescription
        ))
    }

    private func selectedIconDetail(_ entry: SkillCatalogEntry) -> some View {
        let isRunning = model.isRunning(entry)
        let primaryIconAction = model.iconPrimaryAction(for: entry)
        let primaryCommandDisabled = Self.shouldDisableSelectedIconCommand(
            action: primaryIconAction,
            isBusy: model.isBusy,
            hasValidRepo: model.hasValidRepo
        )
        let cliCommandDisabled = Self.shouldDisableIconCLICommand(
            isBusy: model.isBusy,
            hasValidRepo: model.hasValidRepo
        )
        return groupedPanel {
            HStack(alignment: .top, spacing: 14) {
                largeIconView(for: entry)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(entry.displayName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(SkillBarPalette.primaryText)

                        statusChip(
                            entry.statusLabel,
                            tint: entry.isInstalled ? SkillBarPalette.installed.opacity(0.18) : SkillBarPalette.border,
                            foreground: entry.isInstalled ? SkillBarPalette.installed : SkillBarPalette.secondaryText
                        )

                        Spacer(minLength: 0)
                    }

                    Text(entry.primaryDescription)
                        .font(.caption)
                        .foregroundStyle(SkillBarPalette.secondaryText)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        statusChip(entry.categoryLabel, tint: SkillBarPalette.border, foreground: SkillBarPalette.secondaryText)
                        statusChip(iconSourceLabel(for: entry, preferLarge: true), tint: SkillBarPalette.border, foreground: SkillBarPalette.mutedText)
                    }

                    Text(entry.id)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SkillBarPalette.mutedText)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if primaryIconAction == .useDefaultIcon {
                            Button {
                                model.performPrimaryIconAction(for: entry)
                            } label: {
                                actionButtonLabel(
                                    title: isRunning ? primaryIconAction.buttonTitle + "..." : primaryIconAction.buttonTitle,
                                    isRunning: isRunning
                                )
                            }
                            .buttonStyle(.bordered)
                            .disabled(primaryCommandDisabled)
                        } else {
                            Button {
                                model.performPrimaryIconAction(for: entry)
                            } label: {
                                actionButtonLabel(
                                    title: isRunning ? primaryIconAction.buttonTitle + "..." : primaryIconAction.buttonTitle,
                                    isRunning: isRunning
                                )
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(primaryCommandDisabled)
                        }

                        if !entry.isInstalled, primaryIconAction == .installAndPin {
                            Button {
                                model.runAction(for: entry)
                            } label: {
                                actionButtonLabel(title: isRunning ? "Installing" : "Install Only", isRunning: isRunning)
                            }
                            .buttonStyle(.bordered)
                            .help("Install the skill into Codex without changing the current menu bar icon.")
                            .disabled(cliCommandDisabled)
                        }

                        Button("Reveal") {
                            model.revealSkillInFinder(entry)
                        }
                        .buttonStyle(.bordered)
                        .help("Reveal this skill folder in Finder without changing install or menu bar state.")
                        .disabled(Self.shouldDisableSelectedIconReveal(skillPath: entry.skillPath))

                        if Self.shouldShowSelectedIconUpdate(
                            isInstalled: entry.isInstalled,
                            primaryAction: primaryIconAction
                        ) {
                            Button {
                                model.runAction(for: entry)
                            } label: {
                                actionButtonLabel(title: isRunning ? "Updating" : "Update", isRunning: isRunning)
                            }
                            .buttonStyle(.bordered)
                            .help("Update this installed skill without changing the current menu bar icon.")
                            .disabled(cliCommandDisabled)
                        }

                        Spacer(minLength: 0)
                    }

                    Text(primaryIconAction.detailMessage)
                        .font(.caption2)
                        .foregroundStyle(SkillBarPalette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private func pinnedMenuBarStatusStrip(compact: Bool) -> some View {
        HStack(spacing: 8) {
            statusChip(
                model.hasPinnedMenuBarSelection ? "Pinned" : "Default",
                tint: model.hasPinnedMenuBarSelection ? SkillBarPalette.accent.opacity(0.18) : SkillBarPalette.border,
                foreground: model.hasPinnedMenuBarSelection ? SkillBarPalette.accent : SkillBarPalette.secondaryText
            )
            Text(model.menuBarSelectionDisplayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkillBarPalette.primaryText)
                .lineLimit(1)

            Spacer(minLength: 0)

            if model.hasMenuBarRecoveryRepoShortcut {
                pinnedMenuBarRecoveryButton(compact: compact)
            }

            if Self.shouldShowPinnedTileButton(
                hasPinnedSelection: model.hasPinnedMenuBarSelection,
                canRevealPinnedEntry: model.canRevealPinnedMenuBarEntry
            ) {
                Button(model.menuBarRevealButtonTitle) {
                    openCurrentPinnedIcon()
                }
                .buttonStyle(.bordered)
                .controlSize(compact ? .small : .regular)
                .disabled(model.isBusy)
                .help(model.menuBarRevealDetail)
            }

            if model.hasPinnedMenuBarSelection {
                pinnedMenuBarDefaultButton(compact: compact)
            }
        }
    }

    static func pinnedMenuBarRecoveryButtonTitle(compact: Bool, defaultTitle: String) -> String {
        compact ? "Use Repo" : defaultTitle
    }

    static func menuBarRecoveryRepoMenuTitle(compact: Bool) -> String {
        compact ? "Repo" : "Repo Options"
    }

    static func shouldShowPinnedTileButton(hasPinnedSelection: Bool, canRevealPinnedEntry: Bool) -> Bool {
        hasPinnedSelection && canRevealPinnedEntry
    }

    static func shouldShowPinnedMenuBarUpdate(
        hasPinnedSelection: Bool,
        canRevealPinnedEntry: Bool,
        isInstalled: Bool
    ) -> Bool {
        hasPinnedSelection && canRevealPinnedEntry && isInstalled
    }

    static func shouldPromotePackBrowseAction(
        canRunInstallAction: Bool,
        isComplete: Bool,
        isFocused: Bool
    ) -> Bool {
        !isFocused && (!canRunInstallAction || isComplete)
    }

    static func iconGridTitle(hasSearchText: Bool, hasPackFocus: Bool) -> String {
        switch (hasSearchText, hasPackFocus) {
        case (true, true):
            return "Scoped Icons"
        case (true, false):
            return "Search Results"
        case (false, true):
            return "Pack Icons"
        case (false, false):
            return "All Icons"
        }
    }

    static func iconTileHelpText(
        displayName: String,
        statusLabel: String,
        categoryLabel: String,
        primaryDescription: String
    ) -> String {
        "\(displayName) • \(statusLabel) • \(categoryLabel)\nSelect to inspect, reveal, install, update, or pin.\n\(primaryDescription)"
    }

    static func shouldDisableSelectedIconCommand(
        action: SkillIconPrimaryAction,
        isBusy: Bool,
        hasValidRepo: Bool
    ) -> Bool {
        if isBusy {
            return true
        }

        switch action {
        case .useDefaultIcon, .pinToMenuBar:
            return false
        case .installPinnedSkill, .installAndPin:
            return !hasValidRepo
        }
    }

    static func shouldDisableCatalogRowAccessoryAction(
        action: SkillCatalogRowAccessoryAction,
        isBusy: Bool,
        hasValidRepo: Bool
    ) -> Bool {
        if isBusy {
            return true
        }

        switch action {
        case .useDefaultIcon, .pinToMenuBar:
            return false
        case .installPinnedSkill, .installAndPin:
            return !hasValidRepo
        }
    }

    static func shouldPromoteCatalogRowAccessoryAction(action: SkillCatalogRowAccessoryAction) -> Bool {
        action == .installPinnedSkill
    }

    static func shouldShowCatalogRowCLIAction(
        isInstalled: Bool,
        accessoryAction: SkillCatalogRowAccessoryAction
    ) -> Bool {
        isInstalled || accessoryAction != .installPinnedSkill
    }

    static func shouldDisableIconCLICommand(isBusy: Bool, hasValidRepo: Bool) -> Bool {
        isBusy || !hasValidRepo
    }

    static func shouldShowSelectedIconUpdate(isInstalled: Bool, primaryAction _: SkillIconPrimaryAction) -> Bool {
        isInstalled
    }

    static func shouldDisableSelectedIconReveal(skillPath: String) -> Bool {
        skillPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func recentCommandOutputCopyPayload(_ output: String) -> String? {
        output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : output
    }

    private func copyRecentCommandOutputToPasteboard() {
        guard let payload = Self.recentCommandOutputCopyPayload(model.lastCommandOutput) else {
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(payload, forType: .string)
    }

    @ViewBuilder
    private func pinnedMenuBarRecoveryButton(compact: Bool) -> some View {
        let title = Self.pinnedMenuBarRecoveryButtonTitle(compact: compact, defaultTitle: model.menuBarRecoveryActionLabel)
        if model.hasUnavailablePinnedMenuBarSelection {
            pinnedMenuBarRecoveryButtons(compact: compact, title: title, isProminent: true)
        } else {
            pinnedMenuBarRecoveryButtons(compact: compact, title: title, isProminent: false)
        }
    }

    @ViewBuilder
    private func pinnedMenuBarRecoveryButtons(compact: Bool, title: String, isProminent: Bool) -> some View {
        if isProminent {
            Button(title) {
                model.completeMenuBarRecoveryQuickSetup()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(compact ? .small : .regular)
            .disabled(model.isBusy)
            .help("Switch SkillBar to the detected repo clone and recreate the installs folder if needed so the pinned icon becomes available again.")
        } else {
            Button(title) {
                model.completeMenuBarRecoveryQuickSetup()
            }
            .buttonStyle(.bordered)
            .controlSize(compact ? .small : .regular)
            .disabled(model.isBusy)
            .help("Switch SkillBar to the detected repo clone and recreate the installs folder if needed so the pinned icon becomes available again.")
        }

        menuBarRecoveryRepoMenu(compact: compact)
    }

    @ViewBuilder
    private func pinnedMenuBarDefaultButton(compact: Bool) -> some View {
        if model.hasUnavailablePinnedMenuBarSelection {
            Button("Use Default") {
                model.clearMenuBarEntry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(compact ? .small : .regular)
            .disabled(model.isBusy)
            .help(model.unavailablePinnedMenuBarRecoveryDetail)
        } else {
            Button("Use Default") {
                model.clearMenuBarEntry()
            }
            .buttonStyle(.bordered)
            .controlSize(compact ? .small : .regular)
            .disabled(model.isBusy)
            .help("Reset the menu bar icon back to the default SkillBar stack.")
        }
    }

    private func menuBarRecoveryRepoMenu(compact: Bool) -> some View {
        Menu {
            Button(model.menuBarRecoveryRepoActionLabel(actionPrefix: "Open")) {
                model.openMenuBarRecoveryRepoRoot()
            }

            Button(model.menuBarRecoveryRepoActionLabel(actionPrefix: "Reveal")) {
                model.revealMenuBarRecoveryRepoRootInFinder()
            }
        } label: {
            if compact {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 24, height: 24)
            } else {
                Label(Self.menuBarRecoveryRepoMenuTitle(compact: compact), systemImage: "ellipsis.circle")
            }
        }
        .menuStyle(.borderlessButton)
        .controlSize(compact ? .small : .regular)
        .disabled(model.isBusy)
        .help("Open or reveal the detected repo clone in Finder before switching SkillBar to it.")
    }

    static func packRecoveryRepoMenuTitle() -> String {
        "Repo Options"
    }

    private func packRecoveryRepoMenu() -> some View {
        Menu {
            if model.hasPackRecoveryRepoShortcut {
                Button(model.packRecoveryRepoActionLabel(actionPrefix: "Open")) {
                    model.openPackRecoveryRepoRoot()
                }

                Button(model.packRecoveryRepoActionLabel(actionPrefix: "Reveal")) {
                    model.revealPackRecoveryRepoRootInFinder()
                }

                if model.hasValidRepo {
                    Divider()
                }
            }

            if model.hasValidRepo {
                Button("Open Current Repo") {
                    model.openRepoRoot()
                }
            }
        } label: {
            Label(Self.packRecoveryRepoMenuTitle(), systemImage: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .controlSize(.small)
        .disabled(model.isBusy || (!model.hasPackRecoveryRepoShortcut && !model.hasValidRepo))
        .help("Open or reveal repo folders before switching SkillBar or retrying this pack.")
    }

    private func actionButtonLabel(title: String, isRunning: Bool) -> some View {
        HStack(spacing: 6) {
            if isRunning {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 12, height: 12)
            }
            Text(title)
        }
    }

    private struct SettingRowAction: Identifiable {
        let title: String
        let isDisabled: Bool
        let perform: () -> Void

        var id: String { title }
    }

    private func settingRow(
        title: String,
        value: String,
        primaryActionTitle: String,
        primaryAction: @escaping () -> Void,
        secondaryActions: [SettingRowAction] = []
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SkillBarPalette.secondaryText)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Button(primaryActionTitle) {
                        primaryAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isBusy)

                    if !secondaryActions.isEmpty {
                        settingRowOptionsMenu(title: title, actions: secondaryActions)
                    }
                }
            }
            Text(value)
                .font(.caption)
                .foregroundStyle(SkillBarPalette.primaryText)
                .lineLimit(3)
        }
    }

    static func settingRowSecondaryMenuTitle(for title: String) -> String {
        switch title {
        case "Active View":
            return "View Options"
        case "Repo Root":
            return "Repo Options"
        case "Installed Skills":
            return "Folder Options"
        default:
            return "Options"
        }
    }

    private func settingRowOptionsMenu(title: String, actions: [SettingRowAction]) -> some View {
        Menu {
            ForEach(actions) { action in
                Button(action.title) {
                    action.perform()
                }
                .disabled(action.isDisabled)
            }
        } label: {
            Label(Self.settingRowSecondaryMenuTitle(for: title), systemImage: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .controlSize(.small)
        .disabled(actions.allSatisfy { $0.isDisabled })
        .help("Open secondary actions for \(title.lowercased()).")
    }

    private func sectionLabel(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(SkillBarPalette.secondaryText)
            Spacer()
            Text(trailing)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SkillBarPalette.mutedText)
        }
    }

    private func compactMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(SkillBarPalette.primaryText)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SkillBarPalette.mutedText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(groupedBackground())
    }

    private func compactSidebarMetric(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(SkillBarPalette.mutedText)
            Spacer(minLength: 0)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(SkillBarPalette.primaryText)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(SkillBarPalette.surface.opacity(0.74))
        )
    }

    private func sidebarButton(_ section: SkillBarSection) -> some View {
        let isSelected = model.selectedSection == section
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                model.selectedSection = section
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: section.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 17)
                Text(section == .icons ? "Icons" : section.title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? SkillBarPalette.primaryText : SkillBarPalette.secondaryText)
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? SkillBarPalette.accent.opacity(0.18) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func statusChip(_ title: String, tint: Color, foreground: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(tint)
            )
    }

    private func activeScopeClearChip(
        title: String,
        tint: Color,
        foreground: Color,
        clearHelp: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .truncationMode(.tail)

            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .imageScale(.small)
            }
            .buttonStyle(.plain)
            .disabled(model.isBusy)
            .help(clearHelp)
            .accessibilityLabel(clearHelp)
        }
        .foregroundStyle(foreground)
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(tint)
        )
    }

    @ViewBuilder
    private func guardrailShortcutChip(
        title: String,
        tint: Color,
        foreground: Color,
        isInteractive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        if isInteractive {
            Button(action: action) {
                statusChip(title, tint: tint, foreground: foreground)
            }
            .buttonStyle(.plain)
            .disabled(model.isBusy || !model.hasValidRepo)
        } else {
            statusChip(title, tint: tint, foreground: foreground)
        }
    }

    private func groupedPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding(12)
            .background(groupedBackground())
    }

    private func groupedBackground() -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(SkillBarPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(SkillBarPalette.border, lineWidth: 1)
            )
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(SkillBarPalette.secondaryText)
            .padding(.vertical, 10)
    }

    private var activeCatalogScopeDetail: String {
        if model.hasSearchText, let focusedPackTitle = model.focusedPackTitle {
            return "Results are filtered by the current search and limited to the \(focusedPackTitle) pack."
        }

        if let focusedPackTitle = model.focusedPackTitle {
            return "Results are limited to the \(focusedPackTitle) pack until you clear the pack scope."
        }

        return "Results are filtered by the current search until you clear it."
    }

    private var discoverEmptyState: some View {
        contextualEmptyState(
            model.hasValidRepo
                ? "No skills match the current search or pack focus."
                : "Choose a local repo before SkillBar can show the catalog."
        ) {
            if model.hasValidRepo, hasCatalogRecoveryScope {
                Button("Reset View") {
                    resetCatalogRecoveryScope()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
            } else if model.quickSetupRepoRoot != nil {
                Button(model.quickSetupPrimaryActionLabel) {
                    model.completeQuickSetup()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
            }

            Button(model.hasValidRepo ? "Open Packs" : "Open Setup") {
                model.selectedSection = model.hasValidRepo ? .packs : .setup
            }
            .buttonStyle(.bordered)
            .disabled(model.isBusy)

            if model.hasValidRepo {
                Button("Show Icons") {
                    openFullIconBoard()
                }
                .buttonStyle(.bordered)
                .disabled(model.isBusy || model.entries.isEmpty)
            }
        }
    }

    private var installedEmptyState: some View {
        contextualEmptyState(
            model.hasValidRepo
                ? "No installed skills are visible in the current view."
                : "Finish setup before checking installed skills."
        ) {
            if model.hasValidRepo, hasCatalogRecoveryScope {
                Button("Reset View") {
                    resetCatalogRecoveryScope()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
            } else if model.installedSkillsFolderExists {
                Button("Open Folder") {
                    model.openInstalledSkillsFolder()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
            } else {
                Button("Create Folder") {
                    model.createInstalledSkillsFolderIfNeeded()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
            }

            Button(model.hasValidRepo ? "Browse Catalog" : "Open Setup") {
                model.selectedSection = model.hasValidRepo ? .discover : .setup
            }
            .buttonStyle(.bordered)
            .disabled(model.isBusy)

            if model.hasValidRepo {
                Button("Open Packs") {
                    model.selectedSection = .packs
                }
                .buttonStyle(.bordered)
                .disabled(model.isBusy)
            }
        }
    }

    private var packsEmptyState: some View {
        contextualEmptyState(
            model.hasValidRepo
                ? "No packs match the current search."
                : "Choose a repo before browsing pack bundles."
        ) {
            if model.hasValidRepo, model.hasSearchText {
                Button("Clear Search") {
                    model.clearSearch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
            } else if model.quickSetupRepoRoot != nil {
                Button(model.quickSetupPrimaryActionLabel) {
                    model.completeQuickSetup()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
            }

            Button(model.hasValidRepo ? "Browse Catalog" : "Open Setup") {
                model.selectedSection = model.hasValidRepo ? .discover : .setup
            }
            .buttonStyle(.bordered)
            .disabled(model.isBusy)

            if model.hasValidRepo {
                Button("Installed") {
                    model.selectedSection = .installed
                }
                .buttonStyle(.bordered)
                .disabled(model.isBusy)
            }
        }
    }

    private var iconsEmptyState: some View {
        contextualEmptyState(
            model.hasValidRepo
                ? "No icons match the current search or pack focus."
                : "Choose a local repo before SkillBar can show icon choices."
        ) {
            if model.hasValidRepo, hasCatalogRecoveryScope {
                Button("Reset View") {
                    openFullIconBoard()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
            } else if model.quickSetupRepoRoot != nil {
                Button(model.quickSetupPrimaryActionLabel) {
                    model.completeQuickSetup()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
            }

            Button(model.hasValidRepo ? "Browse Catalog" : "Open Setup") {
                model.selectedSection = model.hasValidRepo ? .discover : .setup
            }
            .buttonStyle(.bordered)
            .disabled(model.isBusy)

            if model.hasValidRepo {
                Button("Open Packs") {
                    model.selectedSection = .packs
                }
                .buttonStyle(.bordered)
                .disabled(model.isBusy)
            }
        }
    }

    @ViewBuilder
    private func contextualEmptyState<Actions: View>(
        _ text: String,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            emptyState(text)

            HStack(spacing: 8) {
                actions()
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 2)
    }

    private func resetCatalogRecoveryScope() {
        model.clearSearch()
        model.clearPackFocus()
    }

    private func revealMissingCatalogIcons() {
        openIconsSelectingCatalogEntry(firstMissingCatalogIconEntry)
    }

    private func revealDuplicateCatalogIcons() {
        openIconsSelectingCatalogEntry(firstDuplicateCatalogIconEntry)
    }

    private func revealMissingIconsInCurrentScope() {
        selectedIconID = firstMissingScopedIconEntry?.id
    }

    private func revealDuplicateIconsInCurrentScope() {
        selectedIconID = firstDuplicateScopedIconEntry?.id
    }

    private func openCurrentPinnedIcon() {
        guard model.canRevealPinnedMenuBarEntry else { return }
        model.preparePinnedIconRevealScope()
        selectedIconID = model.menuBarEntry?.id
        model.selectedSection = .icons
    }

    private func openIconsSelectingCatalogEntry(_ entry: SkillCatalogEntry?) {
        resetCatalogRecoveryScope()
        selectedIconID = entry?.id
        model.selectedSection = .icons
    }

    private func openFullIconBoard() {
        resetCatalogRecoveryScope()
        model.selectedSection = .icons
    }

    private func sortedIconEntries(_ entries: [SkillCatalogEntry]) -> [SkillCatalogEntry] {
        entries.sorted {
            if $0.isInstalled != $1.isInstalled {
                return $0.isInstalled && !$1.isInstalled
            }

            if $0.categoryLabel != $1.categoryLabel {
                return $0.categoryLabel < $1.categoryLabel
            }

            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    @ViewBuilder
    private func iconView(for entry: SkillCatalogEntry) -> some View {
        if let image = skillImage(for: entry) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(SkillBarPalette.raised)
                )
        } else {
            Image(systemName: entry.category.symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SkillBarPalette.accentSoft)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(SkillBarPalette.raised)
                )
        }
    }

    @ViewBuilder
    private func largeIconView(for entry: SkillCatalogEntry) -> some View {
        if let image = skillImage(for: entry, preferLarge: true) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(SkillBarPalette.raised)
                )
        } else {
            Image(systemName: entry.category.symbolName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(SkillBarPalette.accentSoft)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(SkillBarPalette.raised)
                )
        }
    }

    private func skillImage(for entry: SkillCatalogEntry, preferLarge: Bool = false) -> NSImage? {
        for path in Self.orderedIconAssetPaths(
            smallPath: entry.iconSmallPath,
            largePath: entry.iconLargePath,
            preferLarge: preferLarge
        ) {
            if let image = NSImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
    }

    static func orderedIconAssetPaths(smallPath: String?, largePath: String?, preferLarge: Bool) -> [String] {
        var seen = Set<String>()
        let orderedPaths = preferLarge ? [largePath, smallPath] : [smallPath, largePath]
        return orderedPaths.compactMap { path in
            guard let path, seen.insert(path).inserted else { return nil }
            return path
        }
    }

    private func iconSourceLabel(for entry: SkillCatalogEntry, preferLarge: Bool = false) -> String {
        Self.iconSourceLabel(
            smallPath: entry.iconSmallPath,
            largePath: entry.iconLargePath,
            categorySymbolName: entry.category.symbolName,
            preferLarge: preferLarge
        )
    }

    static func iconSourceLabel(
        smallPath: String?,
        largePath: String?,
        categorySymbolName: String,
        preferLarge: Bool
    ) -> String {
        if let path = orderedIconAssetPaths(smallPath: smallPath, largePath: largePath, preferLarge: preferLarge).first {
            return "Asset: \(URL(fileURLWithPath: path).lastPathComponent)"
        }

        return "Fallback: \(categorySymbolName)"
    }

    private func syncSelectedIcon() {
        selectedIconID = Self.synchronizedSelectedIconID(
            currentSelection: selectedIconID,
            availableIDs: iconEntryIDs
        )
    }

    static func synchronizedSelectedIconID(currentSelection: String?, availableIDs: [String]) -> String? {
        guard !availableIDs.isEmpty else { return nil }
        if let currentSelection, availableIDs.contains(currentSelection) {
            return currentSelection
        }
        return availableIDs.first
    }

    private var setupQuickActionStatus: String {
        model.quickSetupStatusLabel
    }

    private var iconScopeStatusMessage: String {
        if model.hasSearchText, let focusedPackTitle = model.focusedPackTitle {
            return "Showing icon results filtered by search and the \(focusedPackTitle) pack. Reset View opens the full catalog again."
        }

        if let focusedPackTitle = model.focusedPackTitle {
            return "Showing icons for the \(focusedPackTitle) pack only. Reset View opens the full catalog again."
        }

        if model.hasSearchText {
            return "Showing only icons that match the current search. Reset View opens the full catalog again."
        }

        return "Reset View opens the full icon catalog again."
    }
}
