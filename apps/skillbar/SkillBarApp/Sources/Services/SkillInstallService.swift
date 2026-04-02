import Foundation

struct SkillInstallService {
    func commandDescriptor(for request: SkillCommandRequest) -> SkillCommandDescriptor {
        let executable = URL(fileURLWithPath: request.repoRootPath, isDirectory: true)
            .appendingPathComponent("bin/codex-goated")
            .path

        return SkillCommandDescriptor(
            executablePath: executable,
            arguments: request.action.cliArguments
                + ["--repo-dir", request.repoRootPath]
                + (request.action.includesDestinationPath ? ["--dest", request.destinationPath] : [])
                + (request.action.includesSkillIDs ? request.skillIDs : [])
        )
    }

    func run(_ request: SkillCommandRequest) async throws -> SkillCommandResult {
        let descriptor = commandDescriptor(for: request)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: descriptor.executablePath)
        process.arguments = descriptor.arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let combined = [output, error].filter { !$0.isEmpty }.joined(separator: "\n")

        if process.terminationStatus != 0 {
            throw NSError(
                domain: "SkillInstallService",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: combined.isEmpty ? "Skill command failed." : combined]
            )
        }

        return SkillCommandResult(output: combined, exitCode: process.terminationStatus)
    }
}
