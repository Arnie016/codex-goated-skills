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
    @MainActor
    func defaultPresetsIncludeTelegramOpsBundle() {
        let preset = SkillBarModel.defaultPresets.first(where: { $0.id == "telegram-ops" })
        #expect(preset?.includedSkillIDs == ["telebar", "clipboard-studio"])
    }
}
