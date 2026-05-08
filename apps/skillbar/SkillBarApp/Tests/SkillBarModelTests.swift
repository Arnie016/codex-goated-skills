import Foundation
import Testing
@testable import SkillBar

@MainActor
struct SkillBarModelTests {
    @Test
    func installAndPinPinsOnlyAfterSuccessfulInstall() async throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                #expect(request.action == .install)
                #expect(request.skillIDs == ["demo-skill"])
                #expect(request.packID == nil)
                try FileManager.default.createDirectory(
                    at: fixture.installedDir.appendingPathComponent("demo-skill", isDirectory: true),
                    withIntermediateDirectories: true
                )
                return SkillCommandResult(output: "Installed demo-skill", exitCode: 0)
            }
        )

        let entry = try #require(model.entries.first(where: { $0.id == "demo-skill" }))
        #expect(model.menuBarSkillID == nil)

        model.installAndPin(entry)
        #expect(model.menuBarSkillID == nil)

        await waitUntilIdle(model)

        #expect(model.menuBarSkillID == "demo-skill")
        #expect(model.menuBarEntry?.id == "demo-skill")
        #expect(model.menuBarEntry?.isInstalled == true)
        #expect(model.statusHeadline == "Install + Pin \(entry.displayName) complete")
    }

    @Test
    func installAndPinPreservesPreviousPinnedIconOnFailure() async throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["already-pinned", "demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                #expect(request.action == .install)
                #expect(request.skillIDs == ["demo-skill"])
                #expect(request.packID == nil)
                throw NSError(domain: "SkillBarModelTests", code: 9, userInfo: [
                    NSLocalizedDescriptionKey: "install failed"
                ])
            }
        )

        let pinnedEntry = try #require(model.entries.first(where: { $0.id == "already-pinned" }))
        let targetEntry = try #require(model.entries.first(where: { $0.id == "demo-skill" }))
        model.setMenuBarEntry(pinnedEntry)

        model.installAndPin(targetEntry)
        await waitUntilIdle(model)

        #expect(model.menuBarSkillID == "already-pinned")
        #expect(model.menuBarEntry?.id == "already-pinned")
        #expect(model.statusHeadline == "Install + Pin \(targetEntry.displayName) failed")
        #expect(model.statusDetail.contains("install failed"))
    }

    @Test
    func useSuggestedRepoRootRefreshesCatalogAndPersistsSelection() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let alternateRepoRoot = fixture.root.appendingPathComponent("alternate-repo", isDirectory: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("skills/second-skill", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: alternateRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: second-skill
        description: second skill description
        ---
        # second-skill
        """.write(
            to: alternateRepoRoot.appendingPathComponent("skills/second-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.entries.map(\.id) == ["demo-skill"])

        model.useSuggestedRepoRoot(alternateRepoRoot.path)

        #expect(model.repoRootPath == alternateRepoRoot.path)
        #expect(model.entries.map(\.id) == ["second-skill"])
        #expect(model.suggestedRepoRoots.first == alternateRepoRoot.path)
        #expect(model.alternateSuggestedRepoRoots.contains(fixture.repoRoot.path))
        #expect(!model.alternateSuggestedRepoRoots.contains(alternateRepoRoot.path))
        #expect(model.repoSelectionBadge == "Detected")
        #expect(model.repoSelectionDetail.contains("local clone scan"))
        #expect(fixture.defaults.string(forKey: "skillBar.repoRootPath") == alternateRepoRoot.path)
    }

    @Test
    func completeQuickSetupUsesDetectedRepoAndCreatesInstallsFolder() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let alternateRepoRoot = fixture.root.appendingPathComponent("alternate-repo", isDirectory: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("skills/second-skill", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: alternateRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: second-skill
        description: second skill description
        ---
        # second-skill
        """.write(
            to: alternateRepoRoot.appendingPathComponent("skills/second-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let installsPath = fixture.root.appendingPathComponent("custom-installs", isDirectory: true).path
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: installsPath,
            autoRefresh: true
        )

        try? FileManager.default.removeItem(atPath: installsPath)
        #expect(model.preferredDetectedRepoRoot == alternateRepoRoot.path)
        #expect(model.installedSkillsFolderExists == false)

        model.completeQuickSetup(usingRepoRoot: alternateRepoRoot.path)

        #expect(model.repoRootPath == alternateRepoRoot.path)
        #expect(model.entries.map(\.id) == ["second-skill"])
        #expect(model.installedSkillsFolderExists == true)
        #expect(model.statusHeadline == "Quick setup ready")
        #expect(model.statusDetail.contains("ready for installs and updates"))
    }

    @Test
    func clearCommandOutputRemovesRecentOutputState() async throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { _ in
                SkillCommandResult(output: "Audit line 1\nAudit line 2", exitCode: 0)
            }
        )

        model.runAudit()
        await waitUntilIdle(model)

        #expect(model.hasRecentCommandOutput)
        #expect(model.lastCommandOutput.contains("Audit line 1"))

        model.clearCommandOutput()

        #expect(model.lastCommandOutput.isEmpty)
        #expect(!model.hasRecentCommandOutput)
    }

    @Test
    func preferredDetectedRepoRootSkipsCurrentRepoSelection() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let alternateRepoRoot = fixture.root.appendingPathComponent("alternate-repo", isDirectory: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("skills/second-skill", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: alternateRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: second-skill
        description: second skill description
        ---
        # second-skill
        """.write(
            to: alternateRepoRoot.appendingPathComponent("skills/second-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.preferredDetectedRepoRoot == alternateRepoRoot.path)

        model.useSuggestedRepoRoot(alternateRepoRoot.path)

        #expect(model.preferredDetectedRepoRoot == fixture.repoRoot.path)
    }

    @Test
    func setupRepoShortcutUsesDetectedRepoLabel() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let alternateRepoRoot = fixture.root.appendingPathComponent("alternate-repo", isDirectory: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("skills/second-skill", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: alternateRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: second-skill
        description: second skill description
        ---
        # second-skill
        """.write(
            to: alternateRepoRoot.appendingPathComponent("skills/second-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.setupRepoShortcutPath == alternateRepoRoot.path)
        #expect(model.hasSetupRepoShortcut)
        #expect(model.setupRepoShortcutLabel == "Use alternate-repo")

        model.useSuggestedRepoRoot(alternateRepoRoot.path)

        #expect(model.setupRepoShortcutPath == fixture.repoRoot.path)
        #expect(model.setupRepoShortcutLabel == "Use repo")
    }

    @Test
    func packRecoveryQuickSetupUsesPreferredDetectedRepo() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let alternateRepoRoot = fixture.root.appendingPathComponent("alternate-repo", isDirectory: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("skills/second-skill", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: alternateRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: second-skill
        description: second skill description
        ---
        # second-skill
        """.write(
            to: alternateRepoRoot.appendingPathComponent("skills/second-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let installsPath = fixture.root.appendingPathComponent("custom-installs", isDirectory: true).path
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: installsPath,
            autoRefresh: true
        )

        try? FileManager.default.removeItem(atPath: installsPath)
        #expect(model.packRecoveryRepoRoot == alternateRepoRoot.path)
        #expect(model.hasPackRecoveryRepoShortcut)
        #expect(model.packRecoveryRepoDisplayPath?.contains("alternate-repo") == true)
        #expect(model.packRecoveryUsesCurrentRepoSelection == false)
        #expect(model.packRecoveryPrimaryActionLabel == "Use Detected Repo + Create Folder")
        #expect(model.packRecoveryRepoActionLabel(actionPrefix: "Open") == "Open Detected Repo")
        #expect(model.packRecoveryRepoActionLabel(actionPrefix: "Reveal") == "Reveal Detected Repo")

        model.completePackRecoveryQuickSetup()

        #expect(model.repoRootPath == alternateRepoRoot.path)
        #expect(model.entries.map(\.id) == ["second-skill"])
        #expect(model.installedSkillsFolderExists == true)
        #expect(model.statusHeadline == "Quick setup ready")
    }

    @Test
    func packRecoveryShortcutStaysHiddenWithoutAlternateDetectedRepo() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.packRecoveryRepoRoot == nil)
        #expect(!model.hasPackRecoveryRepoShortcut)
        #expect(model.packRecoveryRepoDisplayPath == nil)
        #expect(model.packRecoveryUsesCurrentRepoSelection == false)
    }

    @Test
    func quickSetupRepoRootFallsBackToCurrentValidRepoWhenNoAlternateCloneExists() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.hasValidRepo)
        #expect(model.preferredDetectedRepoRoot == nil)
        #expect(model.quickSetupRepoRoot == fixture.repoRoot.path)
        #expect(model.quickSetupUsesCurrentRepoSelection)
    }

    @Test
    func completeQuickSetupWithoutAlternateRepoKeepsCurrentSelectionAndCreatesInstallsFolder() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let installsPath = fixture.root.appendingPathComponent("custom-installs", isDirectory: true).path
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: installsPath,
            autoRefresh: true
        )

        try? FileManager.default.removeItem(atPath: installsPath)
        #expect(model.quickSetupRepoRoot == fixture.repoRoot.path)
        #expect(model.quickSetupUsesCurrentRepoSelection)
        #expect(model.installedSkillsFolderExists == false)
        let initialBadge = model.repoSelectionBadge

        model.completeQuickSetup()

        #expect(model.repoRootPath == fixture.repoRoot.path)
        #expect(model.installedSkillsFolderExists == true)
        #expect(model.repoSelectionBadge == initialBadge)
        #expect(model.statusHeadline == "Quick setup ready")
    }

    @Test
    func completeQuickSetupWithInvalidCurrentRepoStopsBeforeCreatingInstallsFolder() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let invalidRepoPath = fixture.root.appendingPathComponent("missing-repo", isDirectory: true).path
        let installsPath = fixture.root.appendingPathComponent("custom-installs", isDirectory: true).path
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: invalidRepoPath,
            installedSkillsPathOverride: installsPath,
            autoRefresh: true
        )

        #expect(model.hasValidRepo == false)
        #expect(model.quickSetupRepoRoot == nil)
        #expect(model.installedSkillsFolderExists == false)
        #expect(model.staleRepoSelectionDetail?.contains("missing-repo") == true)

        model.completeQuickSetup()

        #expect(model.selectedSection == .setup)
        #expect(model.statusHeadline == "Repo path missing")
        #expect(model.statusDetail.contains("Choose a local clone"))
        #expect(FileManager.default.fileExists(atPath: installsPath) == false)
        #expect(model.installedSkillsFolderExists == false)
    }

    @Test
    func invalidCurrentRepoSelectionStaysRecoverableFromSetupRow() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let staleDirectory = fixture.root.appendingPathComponent("stale-selection", isDirectory: true)
        try FileManager.default.createDirectory(at: staleDirectory, withIntermediateDirectories: true)

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: staleDirectory.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.hasValidRepo == false)
        #expect(model.quickSetupRepoRoot == nil)
        #expect(model.hasRecoverableRepoRootSelection)
        #expect(model.staleRepoSelectionDetail?.contains("stale-selection") == true)
        #expect(model.quickSetupStatusLabel == "needs repo")
    }

    @Test
    func quickSetupRepoActionLabelUsesCandidateCopyWhenDetectedRepoDiffers() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let alternateRepoRoot = fixture.root.appendingPathComponent("alternate-repo", isDirectory: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("skills/second-skill", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: alternateRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: second-skill
        description: second skill description
        ---
        # second-skill
        """.write(
            to: alternateRepoRoot.appendingPathComponent("skills/second-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.quickSetupRepoRoot == alternateRepoRoot.path)
        #expect(model.quickSetupUsesCurrentRepoSelection == false)
        #expect(model.canAccessQuickSetupRepoRoot)
        #expect(model.quickSetupPrimaryActionLabel == "Use Detected Repo")
        #expect(model.quickSetupStatusLabel == "alternate-repo")
        #expect(model.quickSetupRepoActionLabel(actionPrefix: "Open") == "Open Detected Repo")
        #expect(model.quickSetupRepoActionLabel(actionPrefix: "Reveal") == "Reveal Detected Repo")
    }

    @Test
    func quickSetupRepoActionLabelUsesRepoCopyWhenCurrentSelectionIsTarget() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.quickSetupRepoRoot == fixture.repoRoot.path)
        #expect(model.quickSetupUsesCurrentRepoSelection)
        #expect(model.canAccessQuickSetupRepoRoot)
        #expect(model.quickSetupPrimaryActionLabel == "Use Current Repo")
        #expect(model.quickSetupStatusLabel == "custom folder")
        #expect(model.quickSetupRepoActionLabel(actionPrefix: "Open") == "Open Current Repo")
        #expect(model.quickSetupRepoActionLabel(actionPrefix: "Reveal") == "Reveal Current Repo")
    }

    @Test
    func quickSetupStatusPrefersCreateInstallsWhenRepoIsValidButFolderMissing() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let installsPath = fixture.root.appendingPathComponent("missing-installs", isDirectory: true).path
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: installsPath,
            autoRefresh: true
        )

        #expect(model.hasValidRepo)
        #expect(model.installedSkillsFolderExists == false)
        #expect(model.quickSetupPrimaryActionLabel == "Use Current Repo + Create Folder")
        #expect(model.quickSetupStatusLabel == "create installs")
    }

    @Test
    func quickSetupPrimaryActionMentionsFolderCreationForDetectedRepoWhenNeeded() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let alternateRepoRoot = fixture.root.appendingPathComponent("alternate-repo", isDirectory: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("skills/second-skill", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: alternateRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: second-skill
        description: second skill description
        ---
        # second-skill
        """.write(
            to: alternateRepoRoot.appendingPathComponent("skills/second-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let installsPath = fixture.root.appendingPathComponent("missing-installs", isDirectory: true).path
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: installsPath,
            autoRefresh: true
        )

        #expect(model.quickSetupUsesCurrentRepoSelection == false)
        #expect(model.installedSkillsFolderExists == false)
        #expect(model.quickSetupPrimaryActionLabel == "Use Detected Repo + Create Folder")
    }

    @Test
    func quickSetupStatusUsesCustomFolderWhenRepoIsValidAndInstallsFolderExists() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let installsDir = fixture.root.appendingPathComponent("custom-installs", isDirectory: true)
        try FileManager.default.createDirectory(at: installsDir, withIntermediateDirectories: true)

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: installsDir.path,
            autoRefresh: true
        )

        #expect(model.hasValidRepo)
        #expect(model.installedSkillsFolderExists)
        #expect(model.usesDefaultInstalledSkillsPath == false)
        #expect(model.quickSetupStatusLabel == "custom folder")
    }

    @Test
    func manualRepoOverrideStaysChosenEvenWhenRepoIsAlsoDetected() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        fixture.defaults.set(fixture.repoRoot.path, forKey: "skillBar.repoRootPath")

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.repoRootPath == fixture.repoRoot.path)
        #expect(model.suggestedRepoRoots.contains(fixture.repoRoot.path))
        #expect(model.repoSelectionBadge == "Chosen")
        #expect(model.repoSelectionDetail.contains("chosen directly"))
    }

    @Test
    func repoShortcutLabelUsesRepoNameWhenUnique() {
        let label = SkillBarModel.repoShortcutLabel(
            for: "/Users/arnav/Desktop/codex-goated-skills",
            among: ["/Users/arnav/Desktop/codex-goated-skills"]
        )

        #expect(label == "Use codex-goated-skills")
    }

    @Test
    func repoShortcutLabelAddsParentFolderWhenRepoNamesRepeat() {
        let label = SkillBarModel.repoShortcutLabel(
            for: "/Users/arnav/Desktop/codex-goated-skills",
            among: [
                "/Users/arnav/Desktop/codex-goated-skills",
                "/Users/arnav/tmp/codex-goated-skills"
            ]
        )

        #expect(label == "Use Desktop/codex-goated-skills")
    }

    @Test
    func repoShortcutLabelAddsMoreAncestorsWhenImmediateParentStillCollides() {
        let label = SkillBarModel.repoShortcutLabel(
            for: "/Users/arnav/work/codex-goated-skills",
            among: [
                "/Users/arnav/work/codex-goated-skills",
                "/tmp/arnav/work/codex-goated-skills"
            ]
        )

        #expect(label == "Use Users/arnav/work/codex-goated-skills")
    }

    @Test
    func useDefaultInstalledSkillsFolderPersistsDefaultPath() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let customInstalledPath = fixture.root.appendingPathComponent("custom-installs", isDirectory: true).path
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: customInstalledPath,
            autoRefresh: true
        )

        #expect(model.installedSkillsPath == customInstalledPath)

        model.useDefaultInstalledSkillsFolder()

        #expect(model.installedSkillsPath == NSHomeDirectory() + "/.codex/skills")
        #expect(fixture.defaults.string(forKey: "skillBar.skillsDirectoryPath") == NSHomeDirectory() + "/.codex/skills")
    }

    @Test
    func usesDefaultInstalledSkillsPathTracksCurrentFolder() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let customInstalledPath = fixture.root.appendingPathComponent("custom-installs", isDirectory: true).path
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: customInstalledPath,
            autoRefresh: true
        )

        #expect(model.usesDefaultInstalledSkillsPath == false)

        model.useDefaultInstalledSkillsFolder()

        #expect(model.usesDefaultInstalledSkillsPath == true)
        #expect(model.shouldOfferDefaultInstallsShortcut == false)
    }

    @Test
    func defaultInstallsShortcutTracksCustomFolderState() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let customFolder = fixture.root.appendingPathComponent("custom-installs", isDirectory: true)
        try FileManager.default.createDirectory(at: customFolder, withIntermediateDirectories: true)

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: customFolder.path,
            autoRefresh: true
        )

        #expect(model.shouldOfferDefaultInstallsShortcut == true)

        model.useDefaultInstalledSkillsFolder()

        #expect(model.shouldOfferDefaultInstallsShortcut == false)
        #expect(model.installedSkillsPath == model.defaultInstalledSkillsPath)
    }

    @Test
    func searchMatchesLongDescriptionWhenShortDescriptionDoesNotContainQuery() throws {
        let fixture = try SkillBarModelFixture(
            skills: [
                .init(
                    id: "demo-skill",
                    name: "Demo Skill",
                    description: "Turn transcripts into operator-ready after-action notes.",
                    shortDescription: "Meeting note formatter"
                )
            ]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        model.searchText = "transcripts"

        #expect(model.filteredEntries.map(\.id) == ["demo-skill"])
    }

    @Test
    func installedSkillsFolderExistsIgnoresPlainFiles() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let filePath = fixture.root.appendingPathComponent("not-a-folder").path
        let created = FileManager.default.createFile(atPath: filePath, contents: Data("demo".utf8))
        #expect(created)

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: filePath,
            autoRefresh: true
        )

        #expect(model.installedSkillsFolderExists == false)
    }

    @Test
    func createInstalledSkillsFolderIfNeededReportsFileConflicts() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let filePath = fixture.root.appendingPathComponent("not-a-folder").path
        let created = FileManager.default.createFile(atPath: filePath, contents: Data("demo".utf8))
        #expect(created)

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: filePath,
            autoRefresh: true
        )

        model.createInstalledSkillsFolderIfNeeded()

        #expect(model.statusHeadline == "Couldn’t create installs folder")
        #expect(model.statusDetail.contains("already exists as a file"))
    }

    @Test
    func iconPrimaryActionMatchesInstallAndPinState() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["available-skill", "installed-skill", "pinned-skill", "pinned-installed-skill"])
        defer { fixture.cleanup() }

        try FileManager.default.createDirectory(
            at: fixture.installedDir.appendingPathComponent("installed-skill", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: fixture.installedDir.appendingPathComponent("pinned-installed-skill", isDirectory: true),
            withIntermediateDirectories: true
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let availableEntry = try #require(model.entries.first(where: { $0.id == "available-skill" }))
        let installedEntry = try #require(model.entries.first(where: { $0.id == "installed-skill" }))
        let pinnedEntry = try #require(model.entries.first(where: { $0.id == "pinned-skill" }))
        let pinnedInstalledEntry = try #require(model.entries.first(where: { $0.id == "pinned-installed-skill" }))

        #expect(model.iconPrimaryAction(for: availableEntry) == .installAndPin)
        #expect(model.iconPrimaryAction(for: installedEntry) == .pinToMenuBar)

        model.setMenuBarEntry(pinnedEntry)
        #expect(model.iconPrimaryAction(for: pinnedEntry) == .installPinnedSkill)

        model.setMenuBarEntry(pinnedInstalledEntry)
        #expect(model.iconPrimaryAction(for: pinnedInstalledEntry) == .useDefaultIcon)
    }

    @Test
    func iconPrimaryActionLabelsStayDirect() {
        #expect(SkillIconPrimaryAction.useDefaultIcon.buttonTitle == "Use Default")
        #expect(SkillIconPrimaryAction.installPinnedSkill.buttonTitle == "Install Skill")
        #expect(SkillIconPrimaryAction.pinToMenuBar.buttonTitle == "Pin to Bar")
        #expect(SkillIconPrimaryAction.installAndPin.buttonTitle == "Install + Pin")
        #expect(SkillIconPrimaryAction.installAndPin.detailMessage.contains("menu bar"))
    }

    @Test
    func catalogRowAccessoryActionMatchesInstallAndPinState() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["available-skill", "installed-skill", "pinned-skill", "pinned-installed-skill"])
        defer { fixture.cleanup() }

        try FileManager.default.createDirectory(
            at: fixture.installedDir.appendingPathComponent("installed-skill", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: fixture.installedDir.appendingPathComponent("pinned-installed-skill", isDirectory: true),
            withIntermediateDirectories: true
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let availableEntry = try #require(model.entries.first(where: { $0.id == "available-skill" }))
        let installedEntry = try #require(model.entries.first(where: { $0.id == "installed-skill" }))
        let pinnedEntry = try #require(model.entries.first(where: { $0.id == "pinned-skill" }))
        let pinnedInstalledEntry = try #require(model.entries.first(where: { $0.id == "pinned-installed-skill" }))

        #expect(model.catalogRowAccessoryAction(for: availableEntry) == .installAndPin)
        #expect(model.catalogRowAccessoryAction(for: installedEntry) == .pinToMenuBar)

        model.setMenuBarEntry(pinnedEntry)
        #expect(model.catalogRowAccessoryAction(for: pinnedEntry) == .installPinnedSkill)

        model.setMenuBarEntry(pinnedInstalledEntry)
        #expect(model.catalogRowAccessoryAction(for: pinnedInstalledEntry) == .useDefaultIcon)
    }

    @Test
    func catalogRowAccessoryActionLabelsStayDirect() {
        #expect(SkillCatalogRowAccessoryAction.useDefaultIcon.buttonTitle == "Use Default")
        #expect(SkillCatalogRowAccessoryAction.installPinnedSkill.buttonTitle == "Install Skill")
        #expect(SkillCatalogRowAccessoryAction.pinToMenuBar.buttonTitle == "Pin Icon")
        #expect(SkillCatalogRowAccessoryAction.installAndPin.buttonTitle == "Install + Pin")
    }

    @Test
    func performCatalogRowAccessoryActionPinsInstalledSkillImmediately() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["installed-skill"])
        defer { fixture.cleanup() }

        try FileManager.default.createDirectory(
            at: fixture.installedDir.appendingPathComponent("installed-skill", isDirectory: true),
            withIntermediateDirectories: true
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let entry = try #require(model.entries.first(where: { $0.id == "installed-skill" }))

        model.performCatalogRowAccessoryAction(for: entry)

        #expect(model.menuBarSkillID == "installed-skill")
        #expect(model.statusHeadline == "\(entry.displayName) is on the menu bar")
    }

    @Test
    func performPrimaryIconActionPinsInstalledSkillImmediately() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["installed-skill"])
        defer { fixture.cleanup() }

        try FileManager.default.createDirectory(
            at: fixture.installedDir.appendingPathComponent("installed-skill", isDirectory: true),
            withIntermediateDirectories: true
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let entry = try #require(model.entries.first(where: { $0.id == "installed-skill" }))

        model.performPrimaryIconAction(for: entry)

        #expect(model.menuBarSkillID == "installed-skill")
        #expect(model.statusHeadline == "\(entry.displayName) is on the menu bar")
    }

    @Test
    func performPrimaryIconActionClearsPinnedInstalledSkill() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["installed-skill"])
        defer { fixture.cleanup() }

        try FileManager.default.createDirectory(
            at: fixture.installedDir.appendingPathComponent("installed-skill", isDirectory: true),
            withIntermediateDirectories: true
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let entry = try #require(model.entries.first(where: { $0.id == "installed-skill" }))
        model.setMenuBarEntry(entry)

        model.performPrimaryIconAction(for: entry)

        #expect(model.menuBarSkillID == nil)
        #expect(model.menuBarSelection == nil)
        #expect(model.statusHeadline == "SkillBar icon reset")
    }

    @Test
    func performPrimaryIconActionInstallsPinnedAvailableSkill() async throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["available-skill"])
        defer { fixture.cleanup() }

        let capturedRequest = ThreadSafeRequestCapture()
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                capturedRequest.set(request)
                try FileManager.default.createDirectory(
                    at: fixture.installedDir.appendingPathComponent("available-skill", isDirectory: true),
                    withIntermediateDirectories: true
                )
                return SkillCommandResult(output: "Installed available-skill", exitCode: 0)
            }
        )

        let entry = try #require(model.entries.first(where: { $0.id == "available-skill" }))
        model.setMenuBarEntry(entry)

        model.performPrimaryIconAction(for: entry)
        await waitUntilIdle(model)

        let request = try #require(capturedRequest.get())
        #expect(request.action == .install)
        #expect(request.skillIDs == ["available-skill"])
        #expect(model.menuBarSkillID == "available-skill")
        #expect(model.menuBarEntry?.isInstalled == true)
        #expect(model.statusHeadline == "Install + Pin \(entry.displayName) complete")
    }

    @Test
    func initNormalizesWrapperRepoPathToNestedClone() throws {
        let fixture = try SkillBarModelFixture(skillIDs: [])
        defer { fixture.cleanup() }

        let wrapperRoot = fixture.root.appendingPathComponent("wrapped", isDirectory: true)
        let nestedRepoRoot = wrapperRoot.appendingPathComponent("codex-goated-skills/codex-goated-skills", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedRepoRoot.appendingPathComponent("skills/demo-skill", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: nestedRepoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: nestedRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: demo-skill
        description: demo skill description
        ---
        # demo-skill
        """.write(
            to: nestedRepoRoot.appendingPathComponent("skills/demo-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: wrapperRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            autoRefresh: true
        )

        #expect(model.repoRootPath == nestedRepoRoot.path)
        #expect(model.entries.map(\.id) == ["demo-skill"])
        #expect(model.repoSelectionBadge == "Normalized")
        #expect(model.repoSelectionSourcePath?.hasSuffix("/wrapped") == true)
        #expect(fixture.defaults.string(forKey: "skillBar.repoRootPath") == nestedRepoRoot.path)
    }

    @Test
    func pinnedMenuBarSelectionSurvivesCatalogLoss() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let entry = try #require(model.entries.first(where: { $0.id == "demo-skill" }))
        model.setMenuBarEntry(entry)

        try FileManager.default.removeItem(at: fixture.repoRoot)
        model.refreshCatalog()

        #expect(model.menuBarSkillID == "demo-skill")
        #expect(model.menuBarEntry == nil)
        #expect(model.menuBarSelection?.displayName == entry.displayName)
        #expect(model.menuBarHelp == "SkillBar • \(entry.displayName) on the menu bar")
    }

    @Test
    func menuBarSelectionDisplayNameFallsBackToDefaultWhenNothingIsPinned() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        #expect(model.hasPinnedMenuBarSelection == false)
        #expect(model.menuBarSelectionDisplayName == "Default SkillBar icon")
    }

    @Test
    func menuBarSelectionDisplayNameUsesPinnedSnapshotAfterCatalogLoss() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let entry = try #require(model.entries.first(where: { $0.id == "demo-skill" }))
        model.setMenuBarEntry(entry)
        try FileManager.default.removeItem(at: fixture.repoRoot)
        model.refreshCatalog()

        #expect(model.hasPinnedMenuBarSelection)
        #expect(model.menuBarSelectionDisplayName == entry.displayName)
    }

    @Test
    func currentPinnedIconShortcutRequiresLiveCatalogEntry() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        #expect(model.canRevealPinnedMenuBarEntry == false)
        #expect(model.hasUnavailablePinnedMenuBarSelection == false)
        #expect(model.menuBarRevealButtonTitle == "Pin an Icon First")
        #expect(model.menuBarRevealDetail.contains("Pin a skill icon first"))

        let entry = try #require(model.entries.first(where: { $0.id == "demo-skill" }))
        model.setMenuBarEntry(entry)

        #expect(model.canRevealPinnedMenuBarEntry)
        #expect(model.hasUnavailablePinnedMenuBarSelection == false)
        #expect(model.menuBarRevealButtonTitle == "Open Pinned Tile")
        #expect(model.menuBarRevealDetail.contains("pinned icon tile"))

        try FileManager.default.removeItem(at: fixture.repoRoot)
        model.refreshCatalog()

        #expect(model.hasPinnedMenuBarSelection)
        #expect(model.canRevealPinnedMenuBarEntry == false)
        #expect(model.hasUnavailablePinnedMenuBarSelection)
        #expect(model.menuBarRevealButtonTitle == "Pinned Tile Missing")
        #expect(model.menuBarRevealDetail.contains("older or different repo selection"))
        #expect(model.unavailablePinnedMenuBarRecoveryDetail.contains("default stack icon"))
    }

    @Test
    func menuBarInstallRecoveryEntryAppearsOnlyForPinnedUninstalledSkill() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["available-skill", "installed-skill"])
        defer { fixture.cleanup() }

        try FileManager.default.createDirectory(
            at: fixture.installedDir.appendingPathComponent("installed-skill", isDirectory: true),
            withIntermediateDirectories: true
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        #expect(model.menuBarInstallRecoveryEntry == nil)

        let availableEntry = try #require(model.entries.first(where: { $0.id == "available-skill" }))
        let installedEntry = try #require(model.entries.first(where: { $0.id == "installed-skill" }))

        model.setMenuBarEntry(availableEntry)
        #expect(model.menuBarInstallRecoveryEntry?.id == "available-skill")

        model.setMenuBarEntry(installedEntry)
        #expect(model.menuBarInstallRecoveryEntry == nil)
    }

    @Test
    func unavailablePinnedMenuBarSelectionExposesDetectedRepoRecoveryShortcut() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let alternateRepoRoot = fixture.root.appendingPathComponent("alternate-repo", isDirectory: true)
        try FileManager.default.createDirectory(
            at: alternateRepoRoot.appendingPathComponent("skills/other-skill", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: alternateRepoRoot.appendingPathComponent("bin", isDirectory: true),
            withIntermediateDirectories: true
        )
        let created = FileManager.default.createFile(
            atPath: alternateRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: other-skill
        description: alternate repo skill
        ---
        # Other Skill
        """.write(
            to: alternateRepoRoot.appendingPathComponent("skills/other-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let entry = try #require(model.entries.first(where: { $0.id == "demo-skill" }))
        model.setMenuBarEntry(entry)
        model.useSuggestedRepoRoot(alternateRepoRoot.path)

        #expect(model.hasUnavailablePinnedMenuBarSelection)
        #expect(model.hasMenuBarRecoveryRepoShortcut)
        #expect(model.menuBarRecoveryRepoRoot == fixture.repoRoot.path)
        #expect(model.menuBarRecoveryActionLabel == "Use Detected Repo")
        #expect(model.menuBarRecoveryRepoActionLabel(actionPrefix: "Open") == "Open Detected Repo")
        #expect(model.menuBarRecoveryRepoActionLabel(actionPrefix: "Reveal") == "Reveal Detected Repo")
        #expect(model.menuBarRecoveryRepoDisplayPath == SkillBarModel.abbreviatedPath(fixture.repoRoot.path))

        model.completeMenuBarRecoveryQuickSetup()

        #expect(model.repoRootPath == fixture.repoRoot.path)
        #expect(model.canRevealPinnedMenuBarEntry)
        #expect(model.hasUnavailablePinnedMenuBarSelection == false)
        #expect(model.hasMenuBarRecoveryRepoShortcut == false)
    }

    @Test
    func clearMenuBarEntryRemovesUnavailablePinnedSelection() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let entry = try #require(model.entries.first(where: { $0.id == "demo-skill" }))
        model.setMenuBarEntry(entry)
        try FileManager.default.removeItem(at: fixture.repoRoot)
        model.refreshCatalog()

        #expect(model.hasUnavailablePinnedMenuBarSelection)

        model.clearMenuBarEntry()

        #expect(model.menuBarSkillID == nil)
        #expect(model.menuBarSelection == nil)
        #expect(model.hasPinnedMenuBarSelection == false)
        #expect(model.hasUnavailablePinnedMenuBarSelection == false)
        #expect(model.menuBarSelectionDisplayName == "Default SkillBar icon")
    }

    @Test
    func packActionsUsePackIdentifiersInsteadOfFlattenedSkillIDs() async throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let capturedRequest = ThreadSafeRequestCapture()
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                capturedRequest.set(request)
                return SkillCommandResult(output: "Pack installed", exitCode: 0)
            }
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        model.runAction(for: pack)
        await waitUntilIdle(model)

        let request = try #require(capturedRequest.get())
        #expect(request.action == .install)
        #expect(request.packID == "demo-pack")
        #expect(request.skillIDs.isEmpty)
    }

    @Test
    func developmentLoopUsesDevelopCommandAction() async throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let capturedRequest = ThreadSafeRequestCapture()
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                capturedRequest.set(request)
                return SkillCommandResult(output: "Developed repo", exitCode: 0)
            }
        )

        model.runDevelopmentLoop()
        await waitUntilIdle(model)

        let request = try #require(capturedRequest.get())
        #expect(request.action == .develop)
        #expect(request.skillIDs.isEmpty)
        #expect(request.packID == nil)
        #expect(model.statusHeadline == "Dev Loop complete")
    }

    @Test
    func packActionsExposeRunningStateOnlyForTheActivePack() async throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                #expect(request.packID == "demo-pack")
                try await Task.sleep(nanoseconds: 60_000_000)
                return SkillCommandResult(output: "Pack installed", exitCode: 0)
            }
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        #expect(model.activePackID == nil)
        #expect(model.isRunning(pack) == false)

        model.runAction(for: pack)

        #expect(model.activePackID == "demo-pack")
        #expect(model.isRunning(pack))

        await waitUntilIdle(model)

        #expect(model.activePackID == nil)
        #expect(model.isRunning(pack) == false)
    }

    @Test
    func focusOnPackFiltersDiscoverEntriesUntilCleared() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        #expect(model.discoverEntries.map(\.id) == ["demo-skill-a", "demo-skill-b", "outside-skill"])

        model.focusOnPack(pack)

        #expect(model.focusedPackID == "demo-pack")
        #expect(model.focusedPackTitle == "Demo Pack")
        #expect(model.discoverEntries.map(\.id) == ["demo-skill-a", "demo-skill-b"])
        #expect(model.statusHeadline == "Browsing Demo Pack")

        model.clearPackFocus()

        #expect(model.focusedPackID == nil)
        #expect(model.focusedPackTitle == nil)
        #expect(model.focusedSkillIDs.isEmpty)
        #expect(model.discoverEntries.map(\.id) == ["demo-skill-a", "demo-skill-b", "outside-skill"])
        #expect(model.statusHeadline == "Catalog ready")
    }

    @Test
    func browsePackClearsSearchAndSwitchesToDiscover() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        model.selectedSection = .packs
        model.searchText = "outside"

        model.browsePack(pack)

        #expect(model.selectedSection == .discover)
        #expect(model.searchText.isEmpty)
        #expect(model.focusedPackID == "demo-pack")
        #expect(model.discoverEntries.map(\.id) == ["demo-skill-a", "demo-skill-b"])
        #expect(model.statusHeadline == "Browsing Demo Pack")
    }

    @Test
    func browsePackIconsClearsSearchAndSwitchesToScopedIcons() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        model.selectedSection = .packs
        model.searchText = "outside"

        model.browsePackIcons(pack)

        #expect(model.selectedSection == .icons)
        #expect(model.searchText.isEmpty)
        #expect(model.focusedPackID == "demo-pack")
        #expect(model.filteredEntries.map(\.id) == ["demo-skill-a", "demo-skill-b"])
        #expect(model.statusHeadline == "Browsing Demo Pack")
    }

    @Test
    func browsePackIconsKeepsFullyBrokenPackInRecoveryView() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["outside-skill"],
            packs: [("broken-pack", "Broken Pack", "Broken summary", ["missing-a", "missing-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "broken-pack" }))
        model.selectedSection = .discover

        model.browsePackIcons(pack)

        #expect(model.selectedSection == .packs)
        #expect(model.focusedPackID == "broken-pack")
        #expect(model.focusedSkillIDs.isEmpty)
        #expect(model.statusHeadline == "Browsing Broken Pack")
        #expect(model.statusDetail.contains("no available skills"))
    }

    @Test
    func browseBrokenPackFocusesOnlyAvailableMembersAndReportsMissingReferences() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["present-skill", "outside-skill"],
            packs: [("broken-pack", "Broken Pack", "Broken summary", ["present-skill", "missing-skill"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "broken-pack" }))
        #expect(pack.browseButtonTitle == "Browse Available")

        model.selectedSection = .packs
        model.browsePack(pack)

        #expect(model.selectedSection == .discover)
        #expect(model.focusedPackID == "broken-pack")
        #expect(model.focusedSkillIDs == ["present-skill"])
        #expect(model.discoverEntries.map(\.id) == ["present-skill"])
        #expect(model.statusHeadline == "Browsing Broken Pack")
        #expect(model.statusDetail == "Showing 1 available skill from this pack. Missing from this repo: missing-skill.")
    }

    @Test
    func reviewBrokenPackWithoutAvailableMembersStaysInPacksAndReportsMissingReferences() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["outside-skill"],
            packs: [("broken-pack", "Broken Pack", "Broken summary", ["missing-a", "missing-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "broken-pack" }))
        #expect(pack.hasNoAvailableMembers)
        #expect(pack.browseButtonTitle == "Review Pack")
        #expect(pack.recoverySummary == "No bundled skills from this pack are available in the current repo.")

        model.selectedSection = .discover
        model.browsePack(pack)

        #expect(model.selectedSection == .packs)
        #expect(model.focusedPackID == "broken-pack")
        #expect(model.focusedSkillIDs.isEmpty)
        #expect(model.hasPackFocus)
        #expect(model.hasActiveCatalogScope)
        #expect(model.statusHeadline == "Browsing Broken Pack")
        #expect(model.statusDetail == "This pack has no available skills in the current repo. Missing from this repo: missing-a, missing-b.")
    }

    @Test
    func brokenPackAvailabilitySummaryUsesResolvedLocalMemberCount() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["present-skill", "outside-skill"],
            packs: [("broken-pack", "Broken Pack", "Broken summary", ["present-skill", "missing-skill"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "broken-pack" }))
        #expect(model.packMembers(for: pack).map(\.id) == ["present-skill"])
        #expect(model.packAvailabilitySummary(for: pack) == "1 of 2 bundled skills are available in this repo.")
    }

    @Test
    func fullyBrokenPackAvailabilitySummaryDoesNotUseDeclaredCountAsBrowsableCopy() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["outside-skill"],
            packs: [("broken-pack", "Broken Pack", "Broken summary", ["missing-a", "missing-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "broken-pack" }))
        #expect(model.packMembers(for: pack).isEmpty)
        #expect(model.packAvailabilitySummary(for: pack) == "0 of 2 bundled skills are available in this repo.")
    }

    @Test
    func switchingRepoClearsPackFocusWhenThatPackDoesNotExistInTheNewRepo() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let alternateRepoRoot = fixture.root.appendingPathComponent("alternate-repo", isDirectory: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("skills/alternate-skill", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: alternateRepoRoot.appendingPathComponent("collections", isDirectory: true), withIntermediateDirectories: true)
        let created = FileManager.default.createFile(
            atPath: alternateRepoRoot.appendingPathComponent("bin/codex-goated").path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)
        try """
        ---
        name: alternate-skill
        description: alternate skill description
        ---
        # alternate-skill
        """.write(
            to: alternateRepoRoot.appendingPathComponent("skills/alternate-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        model.browsePack(pack)
        #expect(model.discoverEntries.map(\.id) == ["demo-skill-a", "demo-skill-b"])

        model.useSuggestedRepoRoot(alternateRepoRoot.path)

        #expect(model.focusedPackID == nil)
        #expect(model.focusedPackTitle == nil)
        #expect(model.focusedSkillIDs.isEmpty)
        #expect(model.discoverEntries.map(\.id) == ["alternate-skill"])
        #expect(model.statusHeadline == "Catalog ready")
    }

    @Test
    func refreshCatalogPreservesFocusedPackStatus() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        model.browsePack(pack)

        model.refreshCatalog()

        #expect(model.focusedPackID == "demo-pack")
        #expect(model.focusedPackTitle == "Demo Pack")
        #expect(model.discoverEntries.map(\.id) == ["demo-skill-a", "demo-skill-b"])
        #expect(model.statusHeadline == "Browsing Demo Pack")
        #expect(model.statusDetail == "Showing 2 bundled skills from this pack in the catalog.")
    }

    @Test
    func focusedPackCanReopenCatalogFromPackRow() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        #expect(model.isFocused(pack) == false)
        #expect(model.canOpenFocusedPackCatalog(pack) == false)

        model.selectedSection = .packs
        model.browsePack(pack)

        #expect(model.isFocused(pack))
        #expect(model.canOpenFocusedPackCatalog(pack))
        #expect(model.selectedSection == .discover)
    }

    @Test
    func focusedBrokenPackWithoutAvailableMembersDoesNotExposeCatalogShortcut() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["outside-skill"],
            packs: [("broken-pack", "Broken Pack", "Broken summary", ["missing-a", "missing-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "broken-pack" }))

        model.selectedSection = .packs
        model.browsePack(pack)

        #expect(model.isFocused(pack))
        #expect(model.canOpenFocusedPackCatalog(pack) == false)
        #expect(model.selectedSection == .packs)
    }

    @Test
    func installsPathRefreshPreservesFocusedPackStatus() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let customInstalledPath = fixture.root.appendingPathComponent("custom-installs", isDirectory: true).path
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: customInstalledPath
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        model.browsePack(pack)

        model.useDefaultInstalledSkillsFolder()

        #expect(model.installedSkillsPath == NSHomeDirectory() + "/.codex/skills")
        #expect(model.focusedPackID == "demo-pack")
        #expect(model.focusedPackTitle == "Demo Pack")
        #expect(model.discoverEntries.map(\.id) == ["demo-skill-a", "demo-skill-b"])
        #expect(model.statusHeadline == "Browsing Demo Pack")
        #expect(model.statusDetail == "Showing 2 bundled skills from this pack in the catalog.")
    }

    @Test
    func preparePinnedIconRevealScopeClearsSearchAndBlockingPackFocus() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pinnedEntry = try #require(model.entries.first(where: { $0.id == "outside-skill" }))
        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))

        model.setMenuBarEntry(pinnedEntry)
        model.searchText = "outside"
        model.focusOnPack(pack)

        #expect(model.pinnedSkillIsOutsideFocusedPack)

        model.preparePinnedIconRevealScope()

        #expect(model.searchText.isEmpty)
        #expect(model.focusedPackID == nil)
        #expect(model.focusedPackTitle == nil)
        #expect(model.focusedSkillIDs.isEmpty)
        #expect(model.statusHeadline == "Catalog ready")
    }

    @Test
    func preparePinnedIconRevealScopeKeepsMatchingPackFocus() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        let pinnedEntry = try #require(model.entries.first(where: { $0.id == "demo-skill-a" }))
        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))

        model.setMenuBarEntry(pinnedEntry)
        model.searchText = "demo"
        model.focusOnPack(pack)

        #expect(model.pinnedSkillIsOutsideFocusedPack == false)

        model.preparePinnedIconRevealScope()

        #expect(model.searchText.isEmpty)
        #expect(model.focusedPackID == "demo-pack")
        #expect(model.focusedPackTitle == "Demo Pack")
        #expect(model.focusedSkillIDs == Set(["demo-skill-a", "demo-skill-b"]))
        #expect(model.statusHeadline == "Browsing Demo Pack")
    }

    @Test
    func duplicateNameCountCanBeScopedToFilteredEntries() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["alpha-skill", "beta-skill", "gamma-skill"])
        defer { fixture.cleanup() }

        try """
        ---
        name: Shared Name
        description: alpha-skill description
        ---
        # Shared Name
        """.write(
            to: fixture.repoRoot.appendingPathComponent("skills/alpha-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        try """
        ---
        name: Shared Name
        description: beta-skill description
        ---
        # Shared Name
        """.write(
            to: fixture.repoRoot.appendingPathComponent("skills/beta-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        #expect(model.duplicateNameCount == 2)

        let alphaOnly = model.entries.filter { $0.id == "alpha-skill" }
        #expect(model.duplicateNameCount(in: alphaOnly) == 0)

        let sharedEntries = model.entries.filter { $0.id == "alpha-skill" || $0.id == "beta-skill" }
        #expect(model.duplicateNameCount(in: sharedEntries) == 2)
    }

    @Test
    func duplicateNameIDsReturnsOnlyEntriesInDuplicateGroups() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["alpha-skill", "beta-skill", "gamma-skill"])
        defer { fixture.cleanup() }

        try """
        ---
        name: Shared Name
        description: alpha-skill description
        ---
        # Shared Name
        """.write(
            to: fixture.repoRoot.appendingPathComponent("skills/alpha-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        try """
        ---
        name: Shared Name
        description: beta-skill description
        ---
        # Shared Name
        """.write(
            to: fixture.repoRoot.appendingPathComponent("skills/beta-skill/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        #expect(model.duplicateNameIDs(in: model.entries) == Set(["alpha-skill", "beta-skill"]))

        let betaOnly = model.entries.filter { $0.id == "beta-skill" }
        #expect(model.duplicateNameIDs(in: betaOnly).isEmpty)
    }

    @Test
    func ignoresNewCommandsWhileAnotherCommandIsStillRunning() async throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["first-skill", "second-skill"])
        defer { fixture.cleanup() }

        actor RequestLog {
            private var requests: [SkillCommandRequest] = []

            func append(_ request: SkillCommandRequest) {
                requests.append(request)
            }

            func snapshot() -> [SkillCommandRequest] {
                requests
            }
        }

        let started = RequestLog()
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                await started.append(request)
                try await Task.sleep(nanoseconds: 80_000_000)
                return SkillCommandResult(output: "Finished \(request.skillIDs.joined(separator: ","))", exitCode: 0)
            }
        )

        let firstEntry = try #require(model.entries.first(where: { $0.id == "first-skill" }))
        let secondEntry = try #require(model.entries.first(where: { $0.id == "second-skill" }))

        model.runAction(for: firstEntry)
        model.runAction(for: secondEntry)

        try? await Task.sleep(nanoseconds: 20_000_000)
        let requests = await started.snapshot()
        #expect(requests.map(\.skillIDs) == [["first-skill"]])
        #expect(model.statusDetail == "Wait for the current command to finish before starting another install, update, audit, or development loop.")

        await waitUntilIdle(model)

        let finishedRequests = await started.snapshot()
        #expect(finishedRequests.map(\.skillIDs) == [["first-skill"]])
    }

    @Test
    func installCreatesMissingDestinationFolderBeforeRunningCommand() async throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        try FileManager.default.removeItem(at: fixture.installedDir)
        #expect(FileManager.default.fileExists(atPath: fixture.installedDir.path) == false)

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                #expect(request.destinationPath == fixture.installedDir.path)
                #expect(FileManager.default.fileExists(atPath: fixture.installedDir.path))
                return SkillCommandResult(output: "Installed demo-skill", exitCode: 0)
            }
        )

        let entry = try #require(model.entries.first(where: { $0.id == "demo-skill" }))
        model.runAction(for: entry)

        await waitUntilIdle(model)

        #expect(FileManager.default.fileExists(atPath: fixture.installedDir.path))
        #expect(model.statusHeadline == "Install \(entry.displayName) complete")
    }

    @Test
    func failedCommandRetainsOutputUntilCleared() async throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { _ in
                throw NSError(
                    domain: "SkillBarModelTests",
                    code: 12,
                    userInfo: [NSLocalizedDescriptionKey: "stderr: failed to install demo-skill"]
                )
            }
        )

        let entry = try #require(model.entries.first(where: { $0.id == "demo-skill" }))
        model.runAction(for: entry)

        await waitUntilIdle(model)

        #expect(model.hasRecentCommandOutput)
        #expect(model.lastCommandOutput.contains("failed to install demo-skill"))

        model.clearCommandOutput()

        #expect(model.hasRecentCommandOutput == false)
        #expect(model.lastCommandOutput.isEmpty)
    }

    @Test
    func packFocusChangesDoNotOverwriteActiveCommandStatus() async throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["demo-skill-a", "demo-skill-b", "outside-skill"],
            packs: [("demo-pack", "Demo Pack", "Demo summary", ["demo-skill-a", "demo-skill-b"])]
        )
        defer { fixture.cleanup() }

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                try await Task.sleep(nanoseconds: 80_000_000)
                return SkillCommandResult(output: "Pack installed", exitCode: 0)
            }
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "demo-pack" }))
        model.runAction(for: pack)

        #expect(model.isBusy)
        #expect(model.statusHeadline == "Install Demo Pack")

        model.focusOnPack(pack)
        #expect(model.focusedPackID == "demo-pack")
        #expect(model.statusHeadline == "Install Demo Pack")

        model.clearPackFocus()
        #expect(model.focusedPackID == nil)
        #expect(model.statusHeadline == "Install Demo Pack")

        await waitUntilIdle(model)

        #expect(model.statusHeadline == "Install Demo Pack complete")
    }

    @Test
    func brokenPackDoesNotRunInstallCommand() throws {
        let fixture = try SkillBarModelFixture(
            skillIDs: ["present-skill"],
            packs: [("broken-pack", "Broken Pack", "Broken summary", ["present-skill", "missing-skill"])]
        )
        defer { fixture.cleanup() }

        let capturedRequest = ThreadSafeRequestCapture()
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                capturedRequest.set(request)
                return SkillCommandResult(output: "unexpected", exitCode: 0)
            }
        )

        let pack = try #require(model.packEntries.first(where: { $0.id == "broken-pack" }))
        #expect(pack.canRunInstallAction == false)

        model.runAction(for: pack)

        #expect(capturedRequest.get() == nil)
        #expect(model.isBusy == false)
        #expect(model.statusHeadline == "Broken Pack needs repo cleanup")
        #expect(model.statusDetail.contains("missing-skill"))
        #expect(model.selectedSection == .packs)
    }

    @Test
    func requestPresetEnableDoesNotOpenConfirmationWhenPresetHasNoAvailableMembers() throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let preset = SkillPreset(
            id: "missing-only",
            title: "Missing Only",
            summary: "No members exist in this repo",
            includedSkillIDs: ["absent-a", "absent-b"]
        )

        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path
        )

        model.requestPresetEnable(preset)

        #expect(model.pendingPreset == nil)
        #expect(model.statusHeadline == "Missing Only has no available skills")
        #expect(model.statusDetail.contains("absent-a"))
        #expect(model.selectedSection == .presets)
    }

    @Test
    func enablePendingPresetInstallsAvailableMembersAndReportsMissingOnSuccess() async throws {
        let fixture = try SkillBarModelFixture(skillIDs: ["demo-skill"])
        defer { fixture.cleanup() }

        let preset = SkillPreset(
            id: "partial-preset",
            title: "Partial Preset",
            summary: "One member exists and one is missing",
            includedSkillIDs: ["demo-skill", "missing-skill"]
        )

        let capturedRequest = ThreadSafeRequestCapture()
        let model = SkillBarModel(
            defaults: fixture.defaults,
            repoRootPathOverride: fixture.repoRoot.path,
            installedSkillsPathOverride: fixture.installedDir.path,
            commandRunner: { request in
                capturedRequest.set(request)
                return SkillCommandResult(output: "Installed demo-skill", exitCode: 0)
            }
        )

        model.requestPresetEnable(preset)
        #expect(model.pendingPreset?.id == "partial-preset")

        model.enablePendingPreset()
        await waitUntilIdle(model)

        let request = try #require(capturedRequest.get())
        #expect(request.action == .install)
        #expect(request.skillIDs == ["demo-skill"])
        #expect(model.pendingPreset == nil)
        #expect(model.statusHeadline == "Enable Partial Preset complete")
        #expect(model.statusDetail.contains("demo-skill"))
        #expect(model.statusDetail.contains("missing-skill"))
    }

    private func waitUntilIdle(_ model: SkillBarModel) async {
        while model.isBusy {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}

private struct SkillBarModelFixture: @unchecked Sendable {
    struct SkillDefinition: Sendable {
        let id: String
        let name: String
        let description: String
        let shortDescription: String?
    }

    let root: URL
    let repoRoot: URL
    let installedDir: URL
    let defaultsSuiteName: String
    let defaults: UserDefaults

    init(skillIDs: [String], packs: [(id: String, title: String, summary: String, skillIDs: [String])] = []) throws {
        root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        repoRoot = root.appendingPathComponent("repo", isDirectory: true)
        installedDir = root.appendingPathComponent("installed", isDirectory: true)
        defaultsSuiteName = "SkillBarModelTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: defaultsSuiteName)!

        try FileManager.default.createDirectory(at: repoRoot.appendingPathComponent("skills", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: installedDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: repoRoot.appendingPathComponent("bin", isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: repoRoot.appendingPathComponent("collections", isDirectory: true), withIntermediateDirectories: true)

        let cliURL = repoRoot.appendingPathComponent("bin/codex-goated")
        let created = FileManager.default.createFile(
            atPath: cliURL.path,
            contents: Data("#!/usr/bin/env bash\nexit 0\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        #expect(created)

        for skillID in skillIDs {
            let skillDir = repoRoot.appendingPathComponent("skills/\(skillID)", isDirectory: true)
            try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)
            try """
            ---
            name: \(skillID)
            description: \(skillID) description
            ---
            # \(skillID)
            """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        }

        for pack in packs {
            let packBody = """
            # title: \(pack.title)
            # summary: \(pack.summary)
            \(pack.skillIDs.joined(separator: "\n"))
            """
            try packBody.write(
                to: repoRoot.appendingPathComponent("collections/\(pack.id).txt"),
                atomically: true,
                encoding: .utf8
            )
        }
    }

    init(skills: [SkillDefinition], packs: [(id: String, title: String, summary: String, skillIDs: [String])] = []) throws {
        try self.init(skillIDs: skills.map(\.id), packs: packs)

        for skill in skills {
            let skillDir = repoRoot.appendingPathComponent("skills/\(skill.id)", isDirectory: true)
            try """
            ---
            name: \(skill.id)
            description: \(skill.description)
            ---
            # \(skill.name)
            """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

            let shortDescription = skill.shortDescription ?? skill.description
            try """
            {
              "name": "\(skill.name)",
              "description": "\(skill.description)",
              "short_description": "\(shortDescription)"
            }
            """.write(to: skillDir.appendingPathComponent("manifest.json"), atomically: true, encoding: .utf8)
        }
    }

    func cleanup() {
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        try? FileManager.default.removeItem(at: root)
    }
}

private final class ThreadSafeRequestCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var request: SkillCommandRequest?

    func set(_ request: SkillCommandRequest) {
        lock.lock()
        defer { lock.unlock() }
        self.request = request
    }

    func get() -> SkillCommandRequest? {
        lock.lock()
        defer { lock.unlock() }
        return request
    }
}
