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

    private var iconEntries: [SkillCatalogEntry] {
        model.filteredEntries.sorted {
            if $0.isInstalled != $1.isInstalled {
                return $0.isInstalled && !$1.isInstalled
            }

            if $0.category.rawValue != $1.category.rawValue {
                return $0.category.rawValue < $1.category.rawValue
            }

            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
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
        .onChange(of: model.searchText) { _, _ in
            syncSelectedIcon()
        }
        .onChange(of: model.entries) { _, _ in
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
        }
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
                        emptyState("No skills match your search.")
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
                    emptyState("No installed skills matched the current filters.")
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
                emptyState("No packs match the current search or repo filters.")
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

            settingRow(title: "Repo Root", value: model.repoRootPath ?? "Not set") {
                model.chooseRepoRoot()
            }

            Divider().overlay(SkillBarPalette.separator)

            settingRow(title: "Installed Skills", value: model.installedSkillsPath) {
                model.chooseInstalledSkillsFolder()
            }

            Divider().overlay(SkillBarPalette.separator)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Menu Bar Icons", trailing: "\(model.availableCount)")

                HStack(spacing: 8) {
                    Button("Open Icons") {
                        model.selectedSection = .icons
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.entries.isEmpty)

                    Button("Refresh") {
                        model.refreshCatalog()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isBusy || !model.hasValidRepo)
                }

                Text("Open a System Settings-style icon board for every installed or available skill, then click a tile to inspect, reveal, install, or update it.")
                    .font(.caption2)
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().overlay(SkillBarPalette.separator)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Repo Health", trailing: model.hasValidRepo ? "ready" : "needs repo")

                HStack(spacing: 8) {
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

                Text("Check catalog freshness and repo integrity from inside SkillBar instead of switching to the shell.")
                    .font(.caption2)
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !model.lastCommandOutput.isEmpty {
                Divider().overlay(SkillBarPalette.separator)
                Text("Recent Command Output")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SkillBarPalette.secondaryText)
                Text(model.lastCommandOutput)
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(SkillBarPalette.primaryText)
                    .lineLimit(10)
            }
        }
    }

    private var iconsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            iconSettingsHeader

            if iconEntries.isEmpty {
                groupedPanel {
                    emptyState("No icons match the current search.")
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
                    }
                    Text("A local settings board for the \(model.availableCount)-skill catalog: each tile is an app-like icon you can inspect and manage without opening GitHub.")
                        .font(.caption)
                        .foregroundStyle(SkillBarPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var iconSettingsGrid: some View {
        groupedPanel {
            sectionLabel("All Icons", trailing: "\(iconEntries.count)")

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
                    }

                    Text(pack.primaryDescription)
                        .font(.caption)
                        .foregroundStyle(SkillBarPalette.secondaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if pack.isComplete {
                    Button {
                        model.runAction(for: pack)
                    } label: {
                        Text(model.action(for: pack).buttonTitle)
                            .font(.caption.weight(.bold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(model.isBusy || !model.hasValidRepo)
                } else {
                    Button {
                        model.runAction(for: pack)
                    } label: {
                        Text(model.action(for: pack).buttonTitle)
                            .font(.caption.weight(.bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(model.isBusy || !model.hasValidRepo)
                }
            }

            if !members.isEmpty {
                Text(members.map(\.displayName).joined(separator: " • "))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SkillBarPalette.mutedText)
                    .lineLimit(2)
            } else {
                Text("\(pack.includedSkillIDs.count) bundled skills")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SkillBarPalette.mutedText)
            }
        }
        .padding(.vertical, 2)
    }

    private func skillRow(_ entry: SkillCatalogEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            iconView(for: entry)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SkillBarPalette.primaryText)

                    statusChip(
                        entry.category.rawValue,
                        tint: SkillBarPalette.border,
                        foreground: SkillBarPalette.secondaryText
                    )

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
                    if entry.isInstalled {
                        Button(model.action(for: entry).buttonTitle) {
                            model.runAction(for: entry)
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isBusy || !model.hasValidRepo)
                    } else {
                        Button(model.action(for: entry).buttonTitle) {
                            model.runAction(for: entry)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isBusy || !model.hasValidRepo)
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

                Text(entry.category.rawValue)
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
                    .fill(entry.isInstalled ? SkillBarPalette.installed : SkillBarPalette.mutedText)
                    .frame(width: 5, height: 5)
            }
            .padding(9)
            .frame(width: 98, height: 112)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? SkillBarPalette.accent.opacity(0.16) : Color.white.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? SkillBarPalette.accent.opacity(0.36) : SkillBarPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("\(entry.displayName) • \(entry.statusLabel)")
    }

    private func selectedIconDetail(_ entry: SkillCatalogEntry) -> some View {
        groupedPanel {
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
                        statusChip(entry.category.rawValue, tint: SkillBarPalette.border, foreground: SkillBarPalette.secondaryText)
                        statusChip(iconSourceLabel(for: entry), tint: SkillBarPalette.border, foreground: SkillBarPalette.mutedText)
                    }

                    Text(entry.id)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(SkillBarPalette.mutedText)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if entry.isInstalled {
                            Button("Update") {
                                model.runAction(for: entry)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Install") {
                                model.runAction(for: entry)
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Button("Reveal") {
                            model.revealSkillInFinder(entry)
                        }
                        .buttonStyle(.bordered)

                        Spacer(minLength: 0)
                    }
                    .disabled(model.isBusy || !model.hasValidRepo)
                }
            }
        }
    }

    private func settingRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SkillBarPalette.secondaryText)
                Spacer()
                Button("Choose") {
                    action()
                }
                .buttonStyle(.bordered)
            }
            Text(value)
                .font(.caption)
                .foregroundStyle(SkillBarPalette.primaryText)
                .lineLimit(3)
        }
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
        if let image = skillImage(for: entry) {
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

    private func skillImage(for entry: SkillCatalogEntry) -> NSImage? {
        for path in [entry.iconSmallPath, entry.iconLargePath].compactMap({ $0 }) {
            if let image = NSImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
    }

    private func iconSourceLabel(for entry: SkillCatalogEntry) -> String {
        if let path = entry.iconSmallPath ?? entry.iconLargePath {
            return "Asset: \(URL(fileURLWithPath: path).lastPathComponent)"
        }

        return "Fallback: \(entry.category.symbolName)"
    }

    private func syncSelectedIcon() {
        guard !iconEntries.isEmpty else {
            selectedIconID = nil
            return
        }

        if let selectedIconID,
           iconEntries.contains(where: { $0.id == selectedIconID }) {
            return
        }

        selectedIconID = iconEntries.first?.id
    }
}
