import Foundation

struct SkillInstallService {
    func commandDescriptor(for request: SkillCommandRequest) -> SkillCommandDescriptor {
        let executable = URL(fileURLWithPath: request.repoRootPath, isDirectory: true)
            .appendingPathComponent("bin/codex-goated")
            .path
        let actionArguments: [String]
        let pathArguments: [String]
        let trailingArguments: [String]

        if let packID = request.packID,
           request.action == .install || request.action == .update {
            actionArguments = ["pack"] + request.action.cliArguments + [packID]
            pathArguments = ["--repo-dir", request.repoRootPath]
                + (request.action.includesDestinationPath ? ["--dest", request.destinationPath] : [])
            trailingArguments = []
        } else {
            actionArguments = request.action.cliArguments
            pathArguments = ["--repo-dir", request.repoRootPath]
                + (request.action.includesDestinationPath ? ["--dest", request.destinationPath] : [])
            trailingArguments = request.action.includesSkillIDs ? request.skillIDs : []
        }

        return SkillCommandDescriptor(
            executablePath: executable,
            arguments: actionArguments + pathArguments + trailingArguments
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
        async let outputData = Self.readToEnd(from: outputPipe.fileHandleForReading)
        async let errorData = Self.readToEnd(from: errorPipe.fileHandleForReading)
        process.waitUntilExit()

        let output = String(data: try await outputData, encoding: .utf8) ?? ""
        let error = String(data: try await errorData, encoding: .utf8) ?? ""
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

    private static func readToEnd(from fileHandle: FileHandle) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try fileHandle.readToEnd() ?? Data())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
