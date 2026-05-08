import Foundation

enum SkillCategory: String, CaseIterable, Identifiable, Codable {
    case productivity = "Productivity"
    case launch = "Launch"
    case telegram = "Telegram"
    case utility = "Utilities"
    case appSpecific = "App-Specific"
    case developerTools = "Developer Tools"
    case workflowAutomation = "Workflow Automation"
    case documents = "Documents"
    case distribution = "Distribution"
    case connectivity = "Connectivity"
    case systemMonitoring = "System Monitoring"
    case community = "Community"
    case presentation = "Presentation"
    case games = "Games"
    case other = "Other"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .productivity: return "bolt.badge.clock"
        case .launch: return "rocket"
        case .telegram: return "paperplane"
        case .utility: return "menubar.rectangle"
        case .appSpecific: return "app.connected.to.app.below.fill"
        case .developerTools: return "terminal"
        case .workflowAutomation: return "wand.and.sparkles"
        case .documents: return "doc.text"
        case .distribution: return "shippingbox"
        case .connectivity: return "network"
        case .systemMonitoring: return "gauge.with.dots.needle.bottom.50percent"
        case .community: return "bubble.left.and.bubble.right"
        case .presentation: return "rectangle.3.group.fill"
        case .games: return "gamecontroller"
        case .other: return "square.grid.2x2"
        }
    }
}

struct SkillCatalogEntry: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let shortDescription: String
    let longDescription: String
    let category: SkillCategory
    let categoryLabel: String
    let skillPath: String
    let iconSmallPath: String?
    let iconLargePath: String?
    let brandColorHex: String?
    let isInstalled: Bool

    var primaryDescription: String {
        shortDescription.isEmpty ? longDescription : shortDescription
    }

    var statusLabel: String {
        isInstalled ? "Installed" : "Available"
    }

    var menuBarSnapshot: PinnedMenuBarEntrySnapshot {
        PinnedMenuBarEntrySnapshot(
            id: id,
            displayName: displayName,
            category: category,
            iconSmallPath: iconSmallPath,
            iconLargePath: iconLargePath
        )
    }
}

struct PinnedMenuBarEntrySnapshot: Hashable, Codable {
    let id: String
    let displayName: String
    let category: SkillCategory
    let iconSmallPath: String?
    let iconLargePath: String?
}

struct RepoRootSelectionContext: Hashable {
    let badge: String
    let detail: String
    let sourcePath: String?
}

struct SkillPreset: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let summary: String
    let includedSkillIDs: [String]
}

struct SkillPackEntry: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let summary: String
    let includedSkillIDs: [String]
    let unresolvedSkillIDs: [String]
    let installedSkillCount: Int

    var resolvedSkillCount: Int {
        includedSkillIDs.count - unresolvedSkillIDs.count
    }

    var hasUnresolvedMembers: Bool {
        !unresolvedSkillIDs.isEmpty
    }

    var hasNoAvailableMembers: Bool {
        resolvedSkillCount == 0
    }

    var canRunInstallAction: Bool {
        !includedSkillIDs.isEmpty && !hasUnresolvedMembers
    }

    var isComplete: Bool {
        canRunInstallAction && installedSkillCount == resolvedSkillCount
    }

    var primaryDescription: String {
        summary.isEmpty ? includedSkillIDs.joined(separator: ", ") : summary
    }

    var statusLabel: String {
        if includedSkillIDs.isEmpty {
            return "Empty"
        }

        if hasUnresolvedMembers {
            return "\(unresolvedSkillIDs.count) missing refs"
        }

        if isComplete {
            return "Ready"
        }

        return "\(installedSkillCount)/\(resolvedSkillCount) installed"
    }

    var browseButtonTitle: String {
        if hasNoAvailableMembers {
            return "Review Pack"
        }

        if hasUnresolvedMembers {
            return "Browse Available"
        }

        return "Browse Skills"
    }

    var recoverySummary: String {
        if hasNoAvailableMembers, hasUnresolvedMembers {
            return "No bundled skills from this pack are available in the current repo."
        }

        if hasUnresolvedMembers {
            return "Some bundled skills are missing from the current repo."
        }

        return "All bundled skills are available in the current repo."
    }
}

enum SkillBarSection: String, CaseIterable, Identifiable {
    case discover = "Discover"
    case installed = "Installed"
    case icons = "Icons"
    case presets = "Presets"
    case packs = "Packs"
    case setup = "Setup"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .discover: return "Discover"
        case .installed: return "Installed"
        case .icons: return "Menu Bar Icons"
        case .presets: return "Presets"
        case .packs: return "Packs"
        case .setup: return "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .discover: return "sparkle.magnifyingglass"
        case .installed: return "checkmark.seal"
        case .icons: return "menubar.rectangle"
        case .presets: return "sparkles.rectangle.stack"
        case .packs: return "shippingbox"
        case .setup: return "gearshape"
        }
    }
}

enum SkillCommandAction: String, Hashable {
    case install
    case update
    case catalogCheck
    case audit
    case develop

    var buttonTitle: String {
        switch self {
        case .install: return "Install"
        case .update: return "Update"
        case .catalogCheck: return "Catalog Check"
        case .audit: return "Audit"
        case .develop: return "Dev Loop"
        }
    }

    var cliArguments: [String] {
        switch self {
        case .install:
            return ["install"]
        case .update:
            return ["update"]
        case .catalogCheck:
            return ["catalog", "check"]
        case .audit:
            return ["audit"]
        case .develop:
            return ["develop"]
        }
    }

    var includesDestinationPath: Bool {
        switch self {
        case .install, .update:
            return true
        case .catalogCheck, .audit, .develop:
            return false
        }
    }

    var includesSkillIDs: Bool {
        switch self {
        case .install, .update:
            return true
        case .catalogCheck, .audit, .develop:
            return false
        }
    }
}

enum SkillIconPrimaryAction: Hashable {
    case useDefaultIcon
    case installPinnedSkill
    case pinToMenuBar
    case installAndPin

    var buttonTitle: String {
        switch self {
        case .useDefaultIcon:
            return "Use Default"
        case .installPinnedSkill:
            return "Install Skill"
        case .pinToMenuBar:
            return "Pin to Bar"
        case .installAndPin:
            return "Install + Pin"
        }
    }

    var detailMessage: String {
        switch self {
        case .useDefaultIcon:
            return "Switch the menu bar back to SkillBar's default icon."
        case .installPinnedSkill:
            return "Keep this icon pinned and install the underlying skill into Codex."
        case .pinToMenuBar:
            return "Use this installed skill's icon in the menu bar."
        case .installAndPin:
            return "Install this skill and make its icon live in the menu bar."
        }
    }
}

enum SkillCatalogRowAccessoryAction: Hashable {
    case useDefaultIcon
    case installPinnedSkill
    case pinToMenuBar
    case installAndPin

    var buttonTitle: String {
        switch self {
        case .useDefaultIcon:
            return "Use Default"
        case .installPinnedSkill:
            return "Install Skill"
        case .pinToMenuBar:
            return "Pin Icon"
        case .installAndPin:
            return "Install + Pin"
        }
    }
}

struct SkillCommandRequest: Hashable {
    let action: SkillCommandAction
    let skillIDs: [String]
    let packID: String?
    let repoRootPath: String
    let destinationPath: String

    init(
        action: SkillCommandAction,
        skillIDs: [String],
        packID: String? = nil,
        repoRootPath: String,
        destinationPath: String
    ) {
        self.action = action
        self.skillIDs = skillIDs
        self.packID = packID
        self.repoRootPath = repoRootPath
        self.destinationPath = destinationPath
    }
}

struct SkillCommandDescriptor: Equatable {
    let executablePath: String
    let arguments: [String]
}

struct SkillCommandResult: Equatable {
    let output: String
    let exitCode: Int32
}
