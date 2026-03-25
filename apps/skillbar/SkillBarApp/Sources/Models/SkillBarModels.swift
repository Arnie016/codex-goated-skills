import Foundation

enum SkillCategory: String, CaseIterable, Identifiable, Codable {
    case productivity = "Productivity"
    case launch = "Launch"
    case telegram = "Telegram"
    case utility = "Utilities"
    case appSpecific = "App-Specific"
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
}

struct SkillPreset: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let summary: String
    let includedSkillIDs: [String]
}

enum SkillBarSection: String, CaseIterable, Identifiable {
    case discover = "Discover"
    case installed = "Installed"
    case presets = "Presets"
    case setup = "Setup"

    var id: String { rawValue }
}

enum SkillCommandAction: String, Hashable {
    case install
    case update

    var buttonTitle: String {
        switch self {
        case .install: return "Install"
        case .update: return "Update"
        }
    }

    var cliVerb: String {
        rawValue
    }
}

struct SkillCommandRequest: Hashable {
    let action: SkillCommandAction
    let skillIDs: [String]
    let repoRootPath: String
    let destinationPath: String
}

struct SkillCommandDescriptor: Equatable {
    let executablePath: String
    let arguments: [String]
}

struct SkillCommandResult: Equatable {
    let output: String
    let exitCode: Int32
}
