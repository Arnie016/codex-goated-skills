import Foundation

struct SkillCatalogService {
    private struct SkillManifest: Decodable {
        let name: String?
        let category: String?
        let shortDescription: String?

        enum CodingKeys: String, CodingKey {
            case name
            case category
            case shortDescription = "short_description"
        }
    }

    func resolveDefaultRepoRoot() -> String? {
        let fileManager = FileManager.default
        let startCandidates = [
            fileManager.currentDirectoryPath,
            ProcessInfo.processInfo.environment["PWD"],
            NSHomeDirectory() + "/Desktop/codex-goated-skills",
            NSHomeDirectory() + "/codex-goated-skills"
        ].compactMap { value -> String? in
            guard let value else { return nil }
            return fileManager.fileExists(atPath: value) ? value : nil
        }

        for start in startCandidates {
            if let found = nearestRepoRoot(startingAt: start) {
                return found
            }
        }
        return nil
    }

    func loadCatalog(repoRootPath: String, installedSkillsPath: String) throws -> [SkillCatalogEntry] {
        let skillsRoot = URL(fileURLWithPath: repoRootPath, isDirectory: true).appendingPathComponent("skills", isDirectory: true)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: skillsRoot.path) else {
            throw NSError(domain: "SkillCatalogService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No skills directory found at \(skillsRoot.path)."])
        }

        let entries = try fileManager.contentsOfDirectory(at: skillsRoot, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            .filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }

        return try entries.compactMap { skillURL in
            try loadEntry(skillURL: skillURL, installedSkillsPath: installedSkillsPath)
        }
    }

    func loadPacks(repoRootPath: String, installedSkillsPath: String) throws -> [SkillPackEntry] {
        let collectionsRoot = URL(fileURLWithPath: repoRootPath, isDirectory: true).appendingPathComponent("collections", isDirectory: true)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: collectionsRoot.path) else {
            return []
        }

        let entries = try fileManager.contentsOfDirectory(at: collectionsRoot, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            .filter { url in
                url.pathExtension == "txt" && !url.hasDirectoryPath
            }
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }

        return try entries.compactMap { packURL in
            try loadPackEntry(packURL: packURL, installedSkillsPath: installedSkillsPath)
        }
    }

    func nearestRepoRoot(startingAt path: String) -> String? {
        let fileManager = FileManager.default
        var url = URL(fileURLWithPath: path, isDirectory: true)

        while true {
            if isRepoRoot(at: url, fileManager: fileManager) {
                return url.path
            }

            let parent = url.deletingLastPathComponent()
            if parent.path == url.path { return nil }
            url = parent
        }
    }

    func isRepoRoot(at path: String) -> Bool {
        isRepoRoot(at: URL(fileURLWithPath: path, isDirectory: true))
    }

    private func isRepoRoot(at url: URL, fileManager: FileManager = .default) -> Bool {
        let skillsDir = url.appendingPathComponent("skills", isDirectory: true)
        let codexGoated = url.appendingPathComponent("bin/codex-goated")
        return fileManager.fileExists(atPath: skillsDir.path) && fileManager.isExecutableFile(atPath: codexGoated.path)
    }

    private func loadEntry(skillURL: URL, installedSkillsPath: String) throws -> SkillCatalogEntry? {
        let skillID = skillURL.lastPathComponent
        let skillMarkdownURL = skillURL.appendingPathComponent("SKILL.md")
        guard FileManager.default.fileExists(atPath: skillMarkdownURL.path) else { return nil }

        let markdown = try String(contentsOf: skillMarkdownURL, encoding: .utf8)
        let frontmatter = parseFrontmatter(markdown)
        let interface = parseOpenAIInterface(at: skillURL.appendingPathComponent("agents/openai.yaml"))
        let manifest = parseManifest(at: skillURL.appendingPathComponent("manifest.json"))
        let installed = FileManager.default.fileExists(atPath: URL(fileURLWithPath: installedSkillsPath, isDirectory: true).appendingPathComponent(skillID).path)

        let displayName = interface["display_name"] ?? manifest?.name ?? frontmatter["name"] ?? skillID
        let shortDescription = interface["short_description"] ?? manifest?.shortDescription ?? frontmatter["description"] ?? ""
        let longDescription = frontmatter["description"] ?? shortDescription
        let iconSmallPath = absoluteAssetPath(skillURL: skillURL, relativePath: interface["icon_small"])
        let iconLargePath = absoluteAssetPath(skillURL: skillURL, relativePath: interface["icon_large"])

        return SkillCatalogEntry(
            id: skillID,
            displayName: displayName.replacingOccurrences(of: "\"", with: ""),
            shortDescription: shortDescription.replacingOccurrences(of: "\"", with: ""),
            longDescription: longDescription.replacingOccurrences(of: "\"", with: ""),
            category: category(for: skillID, manifestCategory: manifest?.category),
            skillPath: skillURL.path,
            iconSmallPath: iconSmallPath,
            iconLargePath: iconLargePath,
            brandColorHex: interface["brand_color"]?.replacingOccurrences(of: "\"", with: ""),
            isInstalled: installed
        )
    }

    private func loadPackEntry(packURL: URL, installedSkillsPath: String) throws -> SkillPackEntry? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: packURL.path) else { return nil }

        let lines = try String(contentsOf: packURL, encoding: .utf8).components(separatedBy: .newlines)
        var title = ""
        var summary = ""
        var skillIDs: [String] = []

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if line.hasPrefix("# title:") {
                title = stripQuotes(String(line.dropFirst("# title:".count)).trimmingCharacters(in: .whitespaces))
                continue
            }

            if line.hasPrefix("# summary:") {
                summary = stripQuotes(String(line.dropFirst("# summary:".count)).trimmingCharacters(in: .whitespaces))
                continue
            }

            if line.hasPrefix("#") {
                continue
            }

            skillIDs.append(line)
        }

        let installedRoot = URL(fileURLWithPath: installedSkillsPath, isDirectory: true)
        let installedCount = skillIDs.filter { skillID in
            fileManager.fileExists(atPath: installedRoot.appendingPathComponent(skillID).path)
        }.count

        return SkillPackEntry(
            id: packURL.deletingPathExtension().lastPathComponent,
            title: title.isEmpty ? packURL.deletingPathExtension().lastPathComponent : title,
            summary: summary,
            includedSkillIDs: skillIDs,
            installedSkillCount: installedCount
        )
    }

    private func parseFrontmatter(_ markdown: String) -> [String: String] {
        let lines = markdown.components(separatedBy: .newlines)
        guard lines.first == "---" else { return [:] }
        var values: [String: String] = [:]

        for line in lines.dropFirst() {
            if line == "---" { break }
            guard let separator = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
            let value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            values[key] = value
        }
        return values
    }

    private func stripQuotes(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, let first = trimmed.first, first == trimmed.last, first == "\"" || first == "'" else {
            return trimmed
        }
        return String(trimmed.dropFirst().dropLast())
    }

    private func parseOpenAIInterface(at url: URL) -> [String: String] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }

        var interface: [String: String] = [:]
        var insideInterface = false
        for line in text.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespacesAndNewlines) == "interface:" {
                insideInterface = true
                continue
            }

            if insideInterface {
                if !line.hasPrefix("  ") || line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if !line.hasPrefix("  ") {
                        break
                    }
                    continue
                }

                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard let separator = trimmed.firstIndex(of: ":") else { continue }
                let key = String(trimmed[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(trimmed[trimmed.index(after: separator)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                interface[key] = value
            }
        }

        return interface
    }

    private func parseManifest(at url: URL) -> SkillManifest? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SkillManifest.self, from: data)
    }

    private func absoluteAssetPath(skillURL: URL, relativePath: String?) -> String? {
        guard let relativePath else { return nil }
        let cleaned = relativePath.replacingOccurrences(of: "\"", with: "")
        guard !cleaned.isEmpty else { return nil }
        return skillURL.appendingPathComponent(cleaned).standardizedFileURL.path
    }

    private func category(for skillID: String, manifestCategory: String?) -> SkillCategory {
        if let manifestCategory,
           let category = category(fromManifestCategory: manifestCategory) {
            return category
        }

        switch skillID {
        case "workspace-doctor", "clipboard-studio", "network-studio", "dark-pdf-studio", "deckdrop-studio":
            return .productivity
        case "repo-launch", "website-drop", "brand-kit", "content-pack":
            return .launch
        case "telebar":
            return .telegram
        case "find-my-phone-studio", "cursor-studio", "folder-studio", "skillbar":
            return .utility
        case "vibe-bluetooth":
            return .appSpecific
        case "minecraft-essentials", "minecraft-skin-studio":
            return .games
        default:
            return .other
        }
    }

    private func category(fromManifestCategory value: String) -> SkillCategory? {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "productivity":
            return .productivity
        case "launch", "launch and distribution":
            return .launch
        case "telegram":
            return .telegram
        case "utilities", "utility", "mac os", "macos":
            return .utility
        case "app-specific", "app specific":
            return .appSpecific
        case "developer tools":
            return .developerTools
        case "workflow automation":
            return .workflowAutomation
        case "documents":
            return .documents
        case "distribution":
            return .distribution
        case "connectivity":
            return .connectivity
        case "system monitoring":
            return .systemMonitoring
        case "community & narrative", "community and narrative", "community":
            return .community
        case "presentation":
            return .presentation
        case "games", "games and consoles":
            return .games
        default:
            return nil
        }
    }
}
