import Foundation
import Testing
@testable import SkillBar

struct SkillCatalogServiceTests {
    @Test
    func parsesSkillMarkdownAndOpenAIMetadata() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let skillDir = tempRoot.appendingPathComponent("skills/demo-skill", isDirectory: true)
        let agentDir = skillDir.appendingPathComponent("agents", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: agentDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)

        try """
        ---
        name: demo-skill
        description: Demo long description
        ---
        # Demo
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        try """
        interface:
          display_name: "Demo Skill"
          short_description: "Short demo"
          icon_small: "./assets/demo.svg"
          brand_color: "#FFFFFF"
        """.write(to: agentDir.appendingPathComponent("openai.yaml"), atomically: true, encoding: .utf8)

        try FileManager.default.createDirectory(at: URL(fileURLWithPath: installedDir.path).appendingPathComponent("demo-skill"), withIntermediateDirectories: true)

        let service = SkillCatalogService()
        let entries = try service.loadCatalog(repoRootPath: tempRoot.path, installedSkillsPath: installedDir.path)

        #expect(entries.count == 1)
        #expect(entries[0].displayName == "Demo Skill")
        #expect(entries[0].shortDescription == "Short demo")
        #expect(entries[0].categoryLabel == "Other")
        #expect(entries[0].isInstalled)
    }

    @Test
    func stripsSingleQuotedInterfaceValuesBeforeBuildingCatalogEntries() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let skillDir = tempRoot.appendingPathComponent("skills/quoted-skill", isDirectory: true)
        let agentDir = skillDir.appendingPathComponent("agents", isDirectory: true)
        let assetsDir = skillDir.appendingPathComponent("assets", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: agentDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)

        try """
        ---
        name: quoted-skill
        description: Quoted long description
        ---
        # Quoted
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        try Data().write(to: assetsDir.appendingPathComponent("quoted.svg"))

        try """
        interface:
          display_name: 'Quoted Skill'
          short_description: 'Single quoted summary'
          icon_small: './assets/quoted.svg'
          icon_large: './assets/quoted.svg'
          brand_color: '#ABCDEF'
        """.write(to: agentDir.appendingPathComponent("openai.yaml"), atomically: true, encoding: .utf8)

        let service = SkillCatalogService()
        let entries = try service.loadCatalog(repoRootPath: tempRoot.path, installedSkillsPath: installedDir.path)

        #expect(entries.count == 1)
        #expect(entries[0].displayName == "Quoted Skill")
        #expect(entries[0].shortDescription == "Single quoted summary")
        #expect(entries[0].iconSmallPath?.hasSuffix("/assets/quoted.svg") == true)
        #expect(entries[0].brandColorHex == "#ABCDEF")
    }

    @Test
    func manifestMetadataOverridesInterfaceValuesAndRepoRelativeAssets() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let skillDir = tempRoot.appendingPathComponent("skills/manifest-skill", isDirectory: true)
        let agentDir = skillDir.appendingPathComponent("agents", isDirectory: true)
        let assetsDir = skillDir.appendingPathComponent("assets", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: agentDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)

        try """
        ---
        name: manifest-skill
        description: Frontmatter description
        ---
        # Manifest
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        try Data().write(to: assetsDir.appendingPathComponent("manifest-small.svg"))
        try Data().write(to: assetsDir.appendingPathComponent("manifest-large.svg"))

        try """
        {
          "name": "Manifest Skill",
          "category": "Launch and Distribution",
          "description": "Manifest long description",
          "short_description": "Manifest short summary",
          "brand_color": "#123456",
          "icon_small": "skills/manifest-skill/assets/manifest-small.svg",
          "icon_large": "skills/manifest-skill/assets/manifest-large.svg"
        }
        """.write(to: skillDir.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)

        try """
        interface:
          display_name: "Interface Skill"
          short_description: "Interface summary"
          icon_small: "./assets/interface-small.svg"
          icon_large: "./assets/interface-large.svg"
          brand_color: "#FFFFFF"
        """.write(to: agentDir.appendingPathComponent("openai.yaml"), atomically: true, encoding: .utf8)

        let service = SkillCatalogService()
        let entries = try service.loadCatalog(repoRootPath: tempRoot.path, installedSkillsPath: installedDir.path)

        #expect(entries.count == 1)
        #expect(entries[0].displayName == "Manifest Skill")
        #expect(entries[0].shortDescription == "Manifest short summary")
        #expect(entries[0].longDescription == "Manifest long description")
        #expect(entries[0].category == .launch)
        #expect(entries[0].categoryLabel == "Launch and Distribution")
        #expect(entries[0].brandColorHex == "#123456")
        #expect(entries[0].iconSmallPath?.hasSuffix("/skills/manifest-skill/assets/manifest-small.svg") == true)
        #expect(entries[0].iconLargePath?.hasSuffix("/skills/manifest-skill/assets/manifest-large.svg") == true)
    }

    @Test
    func invalidManifestStopsCatalogLoadingInsteadOfSilentlyFallingBack() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let skillDir = tempRoot.appendingPathComponent("skills/broken-manifest-skill", isDirectory: true)
        let agentDir = skillDir.appendingPathComponent("agents", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: agentDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)

        try """
        ---
        name: broken-manifest-skill
        description: Frontmatter fallback that should not win
        ---
        # Broken Manifest
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        try """
        { "name": "Broken Manifest Skill",
        """.write(to: skillDir.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)

        try """
        interface:
          display_name: "Legacy Interface Name"
          short_description: "Legacy summary"
        """.write(to: agentDir.appendingPathComponent("openai.yaml"), atomically: true, encoding: .utf8)

        let service = SkillCatalogService()

        #expect(throws: NSError.self) {
            _ = try service.loadCatalog(repoRootPath: tempRoot.path, installedSkillsPath: installedDir.path)
        }
    }

    @Test
    func ignoresInterfaceAssetPathsOutsideTheSkillDirectory() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let skillDir = tempRoot.appendingPathComponent("skills/path-skill", isDirectory: true)
        let agentDir = skillDir.appendingPathComponent("agents", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: agentDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)

        try """
        ---
        name: path-skill
        description: Path skill description
        ---
        # Path
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        try """
        interface:
          display_name: "Path Skill"
          short_description: "Path summary"
          icon_small: "../outside.svg"
          icon_large: "./../../outside.svg"
        """.write(to: agentDir.appendingPathComponent("openai.yaml"), atomically: true, encoding: .utf8)

        let service = SkillCatalogService()
        let entries = try service.loadCatalog(repoRootPath: tempRoot.path, installedSkillsPath: installedDir.path)

        #expect(entries.count == 1)
        #expect(entries[0].iconSmallPath == nil)
        #expect(entries[0].iconLargePath == nil)
    }

    @Test
    func ignoresMissingAssetPathsInsideTheSkillDirectory() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let skillDir = tempRoot.appendingPathComponent("skills/missing-icon-skill", isDirectory: true)
        let agentDir = skillDir.appendingPathComponent("agents", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: agentDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)

        try """
        ---
        name: missing-icon-skill
        description: Missing icon skill description
        ---
        # Missing Icon
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        try """
        interface:
          display_name: "Missing Icon Skill"
          short_description: "Missing icon summary"
          icon_small: "./assets/missing.svg"
          icon_large: "skills/missing-icon-skill/assets/missing-large.svg"
        """.write(to: agentDir.appendingPathComponent("openai.yaml"), atomically: true, encoding: .utf8)

        let service = SkillCatalogService()
        let entries = try service.loadCatalog(repoRootPath: tempRoot.path, installedSkillsPath: installedDir.path)

        #expect(entries.count == 1)
        #expect(entries[0].iconSmallPath == nil)
        #expect(entries[0].iconLargePath == nil)
    }

    @Test
    func ignoresIconPathsThatResolveToDirectories() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let skillDir = tempRoot.appendingPathComponent("skills/directory-icon-skill", isDirectory: true)
        let assetsDir = skillDir.appendingPathComponent("assets", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)

        try """
        ---
        name: directory-icon-skill
        description: Directory icon skill description
        ---
        # Directory Icon
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        try """
        {
          "name": "Directory Icon Skill",
          "icon_small": ".",
          "icon_large": "assets"
        }
        """.write(to: skillDir.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)

        let service = SkillCatalogService()
        let entries = try service.loadCatalog(repoRootPath: tempRoot.path, installedSkillsPath: installedDir.path)

        #expect(entries.count == 1)
        #expect(entries[0].iconSmallPath == nil)
        #expect(entries[0].iconLargePath == nil)
    }

    @Test
    func parsesPackFilesAndInstalledState() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let collectionsDir = tempRoot.appendingPathComponent("collections", isDirectory: true)
        let skillsDir = tempRoot.appendingPathComponent("skills", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: collectionsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skillsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skillsDir.appendingPathComponent("demo-skill-a"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skillsDir.appendingPathComponent("demo-skill-b"), withIntermediateDirectories: true)

        try """
        # title: Demo Pack
        # summary: Demo pack summary
        demo-skill-a
        demo-skill-b
        """.write(to: collectionsDir.appendingPathComponent("demo-pack.txt"), atomically: true, encoding: .utf8)

        try FileManager.default.createDirectory(at: installedDir.appendingPathComponent("demo-skill-a"), withIntermediateDirectories: true)

        let service = SkillCatalogService()
        let packs = try service.loadPacks(repoRootPath: tempRoot.path, installedSkillsPath: installedDir.path)

        #expect(packs.count == 1)
        #expect(packs[0].id == "demo-pack")
        #expect(packs[0].title == "Demo Pack")
        #expect(packs[0].summary == "Demo pack summary")
        #expect(packs[0].includedSkillIDs == ["demo-skill-a", "demo-skill-b"])
        #expect(packs[0].unresolvedSkillIDs.isEmpty)
        #expect(packs[0].installedSkillCount == 1)
        #expect(!packs[0].isComplete)
        #expect(packs[0].statusLabel == "1/2 installed")
    }

    @Test
    func flagsPackFilesWithMissingSkillReferences() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let collectionsDir = tempRoot.appendingPathComponent("collections", isDirectory: true)
        let skillsDir = tempRoot.appendingPathComponent("skills", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: collectionsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skillsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skillsDir.appendingPathComponent("present-skill"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir.appendingPathComponent("present-skill"), withIntermediateDirectories: true)

        try """
        # title: Broken Pack
        # summary: Pack with one missing member
        present-skill
        missing-skill
        """.write(to: collectionsDir.appendingPathComponent("broken-pack.txt"), atomically: true, encoding: .utf8)

        let service = SkillCatalogService()
        let packs = try service.loadPacks(repoRootPath: tempRoot.path, installedSkillsPath: installedDir.path)

        #expect(packs.count == 1)
        #expect(packs[0].includedSkillIDs == ["present-skill", "missing-skill"])
        #expect(packs[0].unresolvedSkillIDs == ["missing-skill"])
        #expect(packs[0].resolvedSkillCount == 1)
        #expect(packs[0].installedSkillCount == 1)
        #expect(!packs[0].canRunInstallAction)
        #expect(!packs[0].isComplete)
        #expect(packs[0].statusLabel == "1 missing refs")
    }

    @Test
    func detectsRepoRootsWithoutDependingOnTheFolderName() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let nestedPath = tempRoot.appendingPathComponent("workspace/deeper", isDirectory: true)
        let skillsDir = tempRoot.appendingPathComponent("skills", isDirectory: true)
        let binDir = tempRoot.appendingPathComponent("bin", isDirectory: true)
        let cliURL = binDir.appendingPathComponent("codex-goated")

        try FileManager.default.createDirectory(at: nestedPath, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skillsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: cliURL.path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )

        #expect(created)

        let service = SkillCatalogService()

        #expect(service.nearestRepoRoot(startingAt: nestedPath.path) == tempRoot.path)
        #expect(service.isRepoRoot(at: tempRoot.path))
    }

    @Test
    func findsNestedRepoRootsWhenStartedFromAWrapperFolder() throws {
        let wrapperRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let repoRoot = wrapperRoot.appendingPathComponent("codex-goated-skills/codex-goated-skills", isDirectory: true)
        let skillsDir = repoRoot.appendingPathComponent("skills", isDirectory: true)
        let binDir = repoRoot.appendingPathComponent("bin", isDirectory: true)
        let cliURL = binDir.appendingPathComponent("codex-goated")

        try FileManager.default.createDirectory(at: skillsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: cliURL.path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )

        #expect(created)

        let service = SkillCatalogService()

        #expect(service.nearestRepoRoot(startingAt: wrapperRoot.path) == nil)
        #expect(service.descendantRepoRoot(startingAt: wrapperRoot.path) == repoRoot.path)
        #expect(service.descendantRepoRoots(startingAt: wrapperRoot.path) == [repoRoot.path])
        #expect(service.normalizedRepoRoot(startingAt: wrapperRoot.path) == repoRoot.path)
    }

    @Test
    func descendantRepoRootsReturnsAllMatchesSortedByDepth() throws {
        let wrapperRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let shallowerRepo = wrapperRoot.appendingPathComponent("alpha-repo", isDirectory: true)
        let deeperRepo = wrapperRoot.appendingPathComponent("nested/beta-repo", isDirectory: true)

        for repoRoot in [shallowerRepo, deeperRepo] {
            try FileManager.default.createDirectory(at: repoRoot.appendingPathComponent("skills", isDirectory: true), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: repoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
            let created = FileManager.default.createFile(
                atPath: repoRoot.appendingPathComponent("bin/codex-goated").path,
                contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
                attributes: [.posixPermissions: 0o755]
            )
            #expect(created)
        }

        let service = SkillCatalogService()

        #expect(service.descendantRepoRoots(startingAt: wrapperRoot.path) == [shallowerRepo.path, deeperRepo.path])
    }

    @Test
    func prioritizesCanonicalRepoRootsAheadOfPublishAndTmpClones() {
        let service = SkillCatalogService()

        let ranked = service.prioritizedRepoRoots(from: [
            "/Users/arnav/Desktop/codex-goated skills/codex-goated-skills/codex-goated-skills/tmp/repo-launch-package-publish-20260416",
            "/Users/arnav/Desktop/codex-goated skills/codex-goated-skills/codex-goated-skills",
            "/Users/arnav/Desktop/codex-goated skills/codex-goated-skills/publish-meeting-link-bridge-20260416",
            "/Users/arnav/Desktop/codex-goated-skills"
        ])

        #expect(ranked == [
            "/Users/arnav/Desktop/codex-goated-skills",
            "/Users/arnav/Desktop/codex-goated skills/codex-goated-skills/codex-goated-skills",
            "/Users/arnav/Desktop/codex-goated skills/codex-goated-skills/publish-meeting-link-bridge-20260416",
            "/Users/arnav/Desktop/codex-goated skills/codex-goated-skills/codex-goated-skills/tmp/repo-launch-package-publish-20260416"
        ])
    }

    @Test
    func prioritizesGitBackedRepoRootsAheadOfShallowerSnapshots() throws {
        let wrapperRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let shallowSnapshot = wrapperRoot.appendingPathComponent("codex-goated skills", isDirectory: true)
        let gitBackedClone = wrapperRoot.appendingPathComponent("nested/codex-goated-skills", isDirectory: true)

        for repoRoot in [shallowSnapshot, gitBackedClone] {
            try FileManager.default.createDirectory(at: repoRoot.appendingPathComponent("skills", isDirectory: true), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: repoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
            let created = FileManager.default.createFile(
                atPath: repoRoot.appendingPathComponent("bin/codex-goated").path,
                contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
                attributes: [.posixPermissions: 0o755]
            )
            #expect(created)
        }

        try FileManager.default.createDirectory(at: gitBackedClone.appendingPathComponent(".git", isDirectory: true), withIntermediateDirectories: true)

        let service = SkillCatalogService()
        let ranked = service.prioritizedRepoRoots(from: [shallowSnapshot.path, gitBackedClone.path])

        #expect(ranked == [gitBackedClone.path, shallowSnapshot.path])
    }

    @Test
    func commandDescriptorUsesCodexGoatedBinaryAndExplicitPaths() {
        let service = SkillInstallService()
        let descriptor = service.commandDescriptor(for: SkillCommandRequest(
            action: .update,
            skillIDs: ["telebar", "clipboard-studio"],
            packID: nil,
            repoRootPath: "/tmp/repo",
            destinationPath: "/tmp/skills"
        ))

        #expect(descriptor.executablePath == "/tmp/repo/bin/codex-goated")
        #expect(descriptor.arguments == ["update", "--repo-dir", "/tmp/repo", "--dest", "/tmp/skills", "telebar", "clipboard-studio"])
    }

    @Test
    func commandDescriptorBuildsRepoHealthCommands() {
        let service = SkillInstallService()

        let catalogCheck = service.commandDescriptor(for: SkillCommandRequest(
            action: .catalogCheck,
            skillIDs: [],
            packID: nil,
            repoRootPath: "/tmp/repo",
            destinationPath: "/tmp/skills"
        ))

        let audit = service.commandDescriptor(for: SkillCommandRequest(
            action: .audit,
            skillIDs: [],
            packID: nil,
            repoRootPath: "/tmp/repo",
            destinationPath: "/tmp/skills"
        ))
        let develop = service.commandDescriptor(for: SkillCommandRequest(
            action: .develop,
            skillIDs: [],
            packID: nil,
            repoRootPath: "/tmp/repo",
            destinationPath: "/tmp/skills"
        ))

        #expect(catalogCheck.executablePath == "/tmp/repo/bin/codex-goated")
        #expect(catalogCheck.arguments == ["catalog", "check", "--repo-dir", "/tmp/repo"])
        #expect(audit.executablePath == "/tmp/repo/bin/codex-goated")
        #expect(audit.arguments == ["audit", "--repo-dir", "/tmp/repo"])
        #expect(develop.executablePath == "/tmp/repo/bin/codex-goated")
        #expect(develop.arguments == ["develop", "--repo-dir", "/tmp/repo"])
    }

    @Test
    func commandDescriptorBuildsPackInstallAndUpdateCommands() {
        let service = SkillInstallService()

        let install = service.commandDescriptor(for: SkillCommandRequest(
            action: .install,
            skillIDs: [],
            packID: "utility-builder-stack",
            repoRootPath: "/tmp/repo",
            destinationPath: "/tmp/skills"
        ))

        let update = service.commandDescriptor(for: SkillCommandRequest(
            action: .update,
            skillIDs: [],
            packID: "utility-builder-stack",
            repoRootPath: "/tmp/repo",
            destinationPath: "/tmp/skills"
        ))

        #expect(install.arguments == ["pack", "install", "utility-builder-stack", "--repo-dir", "/tmp/repo", "--dest", "/tmp/skills"])
        #expect(update.arguments == ["pack", "update", "utility-builder-stack", "--repo-dir", "/tmp/repo", "--dest", "/tmp/skills"])
    }

    @Test
    @MainActor
    func defaultPresetsIncludeTelegramOpsBundle() {
        let preset = SkillBarModel.defaultPresets.first(where: { $0.id == "telegram-ops" })
        #expect(preset?.includedSkillIDs == ["telebar", "clipboard-studio"])
    }

    @Test
    func skillBarPathHelpersKeepSetupCopyCompact() {
        #expect(SkillBarModel.displayName(for: "/Users/arnav/Desktop/codex-goated-skills") == "codex-goated-skills")
        #expect(SkillBarModel.abbreviatedPath("/Users/arnav/.codex/skills") == "~/.codex/skills")
        #expect(SkillBarModel.displayName(for: nil) == nil)
        #expect(SkillBarModel.abbreviatedPath(nil) == nil)
    }

    @Test
    @MainActor
    func clearSearchResetsMainSearchState() {
        let suiteName = "SkillBarModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let model = SkillBarModel(defaults: defaults, autoRefresh: false)
        model.searchText = "icons"

        #expect(model.hasSearchText)

        model.clearSearch()

        #expect(model.searchText.isEmpty)
        #expect(!model.hasSearchText)
    }
}
