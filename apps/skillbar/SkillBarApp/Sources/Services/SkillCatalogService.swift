import Foundation

struct SkillCatalogService {
    private let repoDiscoveryStartPaths: [String]?

    private struct SkillManifest: Decodable {
        let name: String?
        let category: String?
        let description: String?
        let shortDescription: String?
        let brandColor: String?
        let iconSmall: String?
        let iconLarge: String?

        enum CodingKeys: String, CodingKey {
            case name
            case category
            case description
            case shortDescription = "short_description"
            case brandColor = "brand_color"
            case iconSmall = "icon_small"
            case iconLarge = "icon_large"
        }
    }

    init(repoDiscoveryStartPaths: [String]? = nil) {
        self.repoDiscoveryStartPaths = repoDiscoveryStartPaths
    }

    func resolveDefaultRepoRoot() -> String? {
        suggestedRepoRoots().first
    }

    func normalizedRepoRoot(startingAt path: String?) -> String? {
        guard let path, !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let standardized = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL.path

        if isRepoRoot(at: standardized) {
            return standardized
        }

        if let nearest = nearestRepoRoot(startingAt: standardized) {
            return URL(fileURLWithPath: nearest, isDirectory: true).standardizedFileURL.path
        }

        return prioritizedRepoRoots(from: descendantRepoRoots(startingAt: standardized)).first
    }

    func suggestedRepoRoots(maxDepth: Int = 4) -> [String] {
        let fileManager = FileManager.default
        let configuredStartPaths = repoDiscoveryStartPaths ?? [
            fileManager.currentDirectoryPath,
            ProcessInfo.processInfo.environment["PWD"],
            NSHomeDirectory() + "/Desktop/codex-goated-skills",
            NSHomeDirectory() + "/Desktop/codex-goated skills",
            NSHomeDirectory() + "/codex-goated-skills",
            NSHomeDirectory() + "/codex-goated skills"
        ].compactMap { $0 }
        let startCandidates = configuredStartPaths.filter { fileManager.fileExists(atPath: $0) }

        var suggestions: [String] = []
        var seen: Set<String> = []

        for start in startCandidates {
            if let found = nearestRepoRoot(startingAt: start) {
                let standardized = URL(fileURLWithPath: found, isDirectory: true).standardizedFileURL.path
                if seen.insert(standardized).inserted {
                    suggestions.append(standardized)
                }
            }

            for found in descendantRepoRoots(startingAt: start, maxDepth: maxDepth) {
                let standardized = URL(fileURLWithPath: found, isDirectory: true).standardizedFileURL.path
                if seen.insert(standardized).inserted {
                    suggestions.append(standardized)
                }
            }
        }

        return prioritizedRepoRoots(from: suggestions)
    }

    func prioritizedRepoRoots(from candidates: [String]) -> [String] {
        var seen: Set<String> = []
        return candidates
            .map { URL(fileURLWithPath: $0, isDirectory: true).standardizedFileURL.path }
            .filter { seen.insert($0).inserted }
            .sorted { lhs, rhs in
                let lhsScore = repoRootSortScore(for: lhs)
                let rhsScore = repoRootSortScore(for: rhs)
                if lhsScore != rhsScore {
                    return lhsScore < rhsScore
                }
                return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }
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
        let skillsRoot = URL(fileURLWithPath: repoRootPath, isDirectory: true).appendingPathComponent("skills", isDirectory: true)
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: collectionsRoot.path) else {
            return []
        }

        let availableSkillIDs = try fileManager.contentsOfDirectory(at: skillsRoot, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            .filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            .map(\.lastPathComponent)

        let entries = try fileManager.contentsOfDirectory(at: collectionsRoot, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            .filter { url in
                url.pathExtension == "txt" && !url.hasDirectoryPath
            }
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }

        return try entries.compactMap { packURL in
            try loadPackEntry(
                packURL: packURL,
                installedSkillsPath: installedSkillsPath,
                availableSkillIDs: Set(availableSkillIDs)
            )
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

    func descendantRepoRoot(startingAt path: String, maxDepth: Int = 4) -> String? {
        descendantRepoRoots(startingAt: path, maxDepth: maxDepth).first
    }

    func descendantRepoRoots(startingAt path: String, maxDepth: Int = 4) -> [String] {
        guard maxDepth > 0 else { return [] }

        let fileManager = FileManager.default
        let rootURL = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
        guard fileManager.fileExists(atPath: rootURL.path) else { return [] }

        let requestedKeys: Set<URLResourceKey> = [.isDirectoryKey]
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: Array(requestedKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        let rootDepth = rootURL.pathComponents.count
        var matches: [String] = []

        for case let candidateURL as URL in enumerator {
            let standardizedURL = candidateURL.standardizedFileURL
            let depth = standardizedURL.pathComponents.count - rootDepth

            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            guard (try? standardizedURL.resourceValues(forKeys: requestedKeys).isDirectory) == true else {
                continue
            }

            if isRepoRoot(at: standardizedURL, fileManager: fileManager) {
                matches.append(standardizedURL.path)
                enumerator.skipDescendants()
            }
        }

        return matches.sorted {
            let lhsDepth = URL(fileURLWithPath: $0, isDirectory: true).pathComponents.count
            let rhsDepth = URL(fileURLWithPath: $1, isDirectory: true).pathComponents.count
            if lhsDepth != rhsDepth {
                return lhsDepth < rhsDepth
            }
            return $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }

    private func isRepoRoot(at url: URL, fileManager: FileManager = .default) -> Bool {
        let skillsDir = url.appendingPathComponent("skills", isDirectory: true)
        let codexGoated = url.appendingPathComponent("bin/codex-goated")
        return fileManager.fileExists(atPath: skillsDir.path) && fileManager.isExecutableFile(atPath: codexGoated.path)
    }

    private func repoRootSortScore(for path: String) -> (Int, Int, Int, Int, Int) {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        let components = url.pathComponents.map { $0.lowercased() }
        let basename = url.lastPathComponent.lowercased()
        let gitPenalty = hasGitMetadata(at: url) ? 0 : 1
        let liveWorkspacePenalty = hasSkillBarWorkspace(at: url) ? 0 : 1

        let noisePenalty = components.reduce(into: 0) { total, component in
            if component == "tmp" || component == "temp" {
                total += 4
            }
            if component == "out" || component == "output" {
                total += 2
            }
            if component.hasPrefix("publish-") || component.contains("branchbase") || component.hasPrefix("branch-") {
                total += 3
            }
        }

        let canonicalNamePenalty = (basename == "codex-goated-skills" || basename == "codex-goated skills") ? 0 : 1
        let depthPenalty = url.pathComponents.count
        return (gitPenalty, liveWorkspacePenalty, noisePenalty, canonicalNamePenalty, depthPenalty)
    }

    private func hasGitMetadata(at url: URL) -> Bool {
        let gitURL = url.appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitURL.path)
    }

    private func hasSkillBarWorkspace(at url: URL) -> Bool {
        let projectSpecURL = url.appendingPathComponent("apps/skillbar/project.yml")
        let sourcesURL = url.appendingPathComponent("apps/skillbar/SkillBarApp/Sources", isDirectory: true)
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: projectSpecURL.path) && fileManager.fileExists(atPath: sourcesURL.path)
    }

    private func loadEntry(skillURL: URL, installedSkillsPath: String) throws -> SkillCatalogEntry? {
        let skillID = skillURL.lastPathComponent
        let skillMarkdownURL = skillURL.appendingPathComponent("SKILL.md")
        guard FileManager.default.fileExists(atPath: skillMarkdownURL.path) else { return nil }

        let markdown = try String(contentsOf: skillMarkdownURL, encoding: .utf8)
        let frontmatter = parseFrontmatter(markdown)
        let interface = parseOpenAIInterface(at: skillURL.appendingPathComponent("agents/openai.yaml"))
        let manifest = try parseManifest(at: skillURL.appendingPathComponent("manifest.json"))
        let installed = FileManager.default.fileExists(atPath: URL(fileURLWithPath: installedSkillsPath, isDirectory: true).appendingPathComponent(skillID).path)

        let displayName = stripQuotes(manifest?.name ?? interface["display_name"] ?? frontmatter["name"] ?? skillID)
        let shortDescription = stripQuotes(manifest?.shortDescription ?? interface["short_description"] ?? frontmatter["description"] ?? "")
        let longDescription = stripQuotes(manifest?.description ?? frontmatter["description"] ?? shortDescription)
        let iconSmallPath = absoluteAssetPath(skillURL: skillURL, relativePath: manifest?.iconSmall ?? interface["icon_small"])
        let iconLargePath = absoluteAssetPath(skillURL: skillURL, relativePath: manifest?.iconLarge ?? interface["icon_large"])

        let resolvedCategory = category(for: skillID, manifestCategory: manifest?.category)

        return SkillCatalogEntry(
            id: skillID,
            displayName: displayName,
            shortDescription: shortDescription,
            longDescription: longDescription,
            category: resolvedCategory,
            categoryLabel: stripQuotes(manifest?.category ?? resolvedCategory.rawValue),
            skillPath: skillURL.path,
            iconSmallPath: iconSmallPath,
            iconLargePath: iconLargePath,
            brandColorHex: (manifest?.brandColor ?? interface["brand_color"]).map(stripQuotes),
            isInstalled: installed
        )
    }

    private func loadPackEntry(
        packURL: URL,
        installedSkillsPath: String,
        availableSkillIDs: Set<String>
    ) throws -> SkillPackEntry? {
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

        let unresolvedSkillIDs = skillIDs.filter { !availableSkillIDs.contains($0) }
        let resolvedSkillIDs = skillIDs.filter { availableSkillIDs.contains($0) }

        let installedRoot = URL(fileURLWithPath: installedSkillsPath, isDirectory: true)
        let installedCount = resolvedSkillIDs.filter { skillID in
            fileManager.fileExists(atPath: installedRoot.appendingPathComponent(skillID).path)
        }.count

        return SkillPackEntry(
            id: packURL.deletingPathExtension().lastPathComponent,
            title: title.isEmpty ? packURL.deletingPathExtension().lastPathComponent : title,
            summary: summary,
            includedSkillIDs: skillIDs,
            unresolvedSkillIDs: unresolvedSkillIDs,
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

    private func parseManifest(at url: URL) throws -> SkillManifest? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SkillManifest.self, from: data)
        } catch {
            throw NSError(
                domain: "SkillCatalogService",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid manifest at \(url.path): \(error.localizedDescription)"
                ]
            )
        }
    }

    private func absoluteAssetPath(skillURL: URL, relativePath: String?) -> String? {
        guard let relativePath else { return nil }
        let cleaned = stripQuotes(relativePath)
        guard !cleaned.isEmpty else { return nil }
        let skillRoot = skillURL.standardizedFileURL.path
        let repoRoot = skillURL.deletingLastPathComponent().deletingLastPathComponent()
        let assetBase = cleaned.hasPrefix("skills/\(skillURL.lastPathComponent)/") ? repoRoot : skillURL
        let assetPath = assetBase.appendingPathComponent(cleaned).standardizedFileURL.path
        guard assetPath == skillRoot || assetPath.hasPrefix(skillRoot + "/") else {
            return nil
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: assetPath, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            return nil
        }
        return assetPath
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
