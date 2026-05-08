import Foundation
import Testing
@testable import SkillBar

struct SkillInstallServiceExecutionTests {
    @Test
    func runCapturesCombinedOutputWithoutDeadlocking() async throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let binDir = tempRoot.appendingPathComponent("bin", isDirectory: true)
        let cliURL = binDir.appendingPathComponent("codex-goated")

        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
        let lineCount = 4096
        let script = """
        #!/usr/bin/env bash
        set -euo pipefail
        for i in $(seq 1 \(lineCount)); do
          printf 'stdout-%s\\n' "$i"
          printf 'stderr-%s\\n' "$i" >&2
        done
        """
        let created = FileManager.default.createFile(
            atPath: cliURL.path,
            contents: Data(script.utf8),
            attributes: [.posixPermissions: 0o755]
        )

        #expect(created)

        let service = SkillInstallService()
        let result = try await service.run(
            SkillCommandRequest(
                action: .audit,
                skillIDs: [],
                packID: nil,
                repoRootPath: tempRoot.path,
                destinationPath: "/tmp/skills"
            )
        )

        #expect(result.exitCode == 0)
        #expect(result.output.contains("stdout-1"))
        #expect(result.output.contains("stderr-1"))
        #expect(result.output.contains("stdout-\(lineCount)"))
        #expect(result.output.contains("stderr-\(lineCount)"))
    }

    @Test
    func runSurfacesFailureOutput() async throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let binDir = tempRoot.appendingPathComponent("bin", isDirectory: true)
        let cliURL = binDir.appendingPathComponent("codex-goated")

        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
        let script = """
        #!/usr/bin/env bash
        printf 'failed to install\\n' >&2
        exit 7
        """
        let created = FileManager.default.createFile(
            atPath: cliURL.path,
            contents: Data(script.utf8),
            attributes: [.posixPermissions: 0o755]
        )

        #expect(created)

        let service = SkillInstallService()

        do {
            _ = try await service.run(
                SkillCommandRequest(
                    action: .install,
                    skillIDs: ["skillbar"],
                    packID: nil,
                    repoRootPath: tempRoot.path,
                    destinationPath: "/tmp/skills"
                )
            )
            Issue.record("Expected service.run to throw for a failing CLI process.")
        } catch {
            let nsError = error as NSError
            #expect(nsError.code == 7)
            #expect(nsError.localizedDescription.contains("failed to install"))
        }
    }
}
