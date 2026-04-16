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
        #expect(entries[0].isInstalled)
    }

    @Test
    func parsesPackFilesAndInstalledState() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let collectionsDir = tempRoot.appendingPathComponent("collections", isDirectory: true)
        let installedDir = tempRoot.appendingPathComponent("installed", isDirectory: true)

        try FileManager.default.createDirectory(at: collectionsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)

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
        #expect(packs[0].installedSkillCount == 1)
        #expect(!packs[0].isComplete)
        #expect(packs[0].statusLabel == "1/2 installed")
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
    func commandDescriptorUsesCodexGoatedBinaryAndExplicitPaths() {
        let service = SkillInstallService()
        let descriptor = service.commandDescriptor(for: SkillCommandRequest(
            action: .update,
            skillIDs: ["telebar", "clipboard-studio"],
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
            repoRootPath: "/tmp/repo",
            destinationPath: "/tmp/skills"
        ))

        let audit = service.commandDescriptor(for: SkillCommandRequest(
            action: .audit,
            skillIDs: [],
            repoRootPath: "/tmp/repo",
            destinationPath: "/tmp/skills"
        ))

        #expect(catalogCheck.executablePath == "/tmp/repo/bin/codex-goated")
        #expect(catalogCheck.arguments == ["catalog", "check", "--repo-dir", "/tmp/repo"])
        #expect(audit.executablePath == "/tmp/repo/bin/codex-goated")
        #expect(audit.arguments == ["audit", "--repo-dir", "/tmp/repo"])
    }

    @Test
    @MainActor
    func defaultPresetsIncludeTelegramOpsBundle() {
        let preset = SkillBarModel.defaultPresets.first(where: { $0.id == "telegram-ops" })
        #expect(preset?.includedSkillIDs == ["telebar", "clipboard-studio"])
    }
}
