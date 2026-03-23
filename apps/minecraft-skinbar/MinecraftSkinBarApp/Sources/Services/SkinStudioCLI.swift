import AppKit
import Foundation

struct SkinStudioResult {
    var rawURL: URL?
    var skinURL: URL?
    var previewURL: URL?
    var launcherFileURL: URL?
    var registeredSkinID: String?
    var outputText: String
}

struct SkinStudioCLI {
    private let environment = ProcessInfo.processInfo.environment

    struct Error: LocalizedError {
        let message: String
        let output: String

        var errorDescription: String? { message }
    }

    func generateAndRegister(
        prompt: String,
        name: String,
        slim: Bool,
        outputDirectory: URL,
        apiKey: String?
    ) async throws -> SkinStudioResult {
        var arguments = [
            "go",
            "--prompt", prompt,
            "--name", name,
            "--out-dir", outputDirectory.path
        ]
        if slim {
            arguments.append("--slim")
        }
        return try await run(arguments: arguments, apiKey: apiKey)
    }

    func registerExistingSkin(
        skinURL: URL,
        name: String,
        slim: Bool,
        apiKey: String?
    ) async throws -> SkinStudioResult {
        var arguments = [
            "register",
            "--skin", skinURL.path,
            "--name", name
        ]
        if slim {
            arguments.append("--slim")
        }
        return try await run(arguments: arguments, apiKey: apiKey)
    }

    var environmentAPIKey: String {
        environment["OPENAI_API_KEY"] ?? ""
    }

    func openLauncher() {
        let workspace = NSWorkspace.shared
        let configuration = NSWorkspace.OpenConfiguration()

        if let launcherURL = workspace.urlForApplication(withBundleIdentifier: "com.mojang.minecraftlauncher") {
            workspace.openApplication(at: launcherURL, configuration: configuration) { _, _ in }
            return
        }

        let fallbackPaths = [
            "/Applications/Minecraft Launcher.app",
            "\(NSHomeDirectory())/Applications/Minecraft Launcher.app"
        ]

        for path in fallbackPaths {
            let launcherURL = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: launcherURL.path) {
                workspace.openApplication(at: launcherURL, configuration: configuration) { _, _ in }
                return
            }
        }

        workspace.open(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support/minecraft"))
    }

    private func run(arguments: [String], apiKey: String?) async throws -> SkinStudioResult {
        let scriptURL = try resolveScriptURL()
        let uvURL = try resolveUVURL()

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()

                process.executableURL = uvURL
                process.arguments = ["run", "--with", "pillow", "python", scriptURL.path] + arguments
                process.standardOutput = pipe
                process.standardError = pipe
                process.environment = mergedEnvironment(apiKey: apiKey, uvURL: uvURL)

                do {
                    try process.run()
                    process.waitUntilExit()

                    let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: outputData, encoding: .utf8) ?? ""

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: parse(output: output))
                    } else {
                        continuation.resume(throwing: Error(message: "The skin tool exited with code \(process.terminationStatus).", output: output))
                    }
                } catch {
                    continuation.resume(throwing: Error(message: error.localizedDescription, output: ""))
                }
            }
        }
    }

    private func resolveScriptURL() throws -> URL {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let fileManager = FileManager.default
        let directCandidates = [
            home.appendingPathComponent(".codex/skills/minecraft-skin-studio/scripts/minecraft_skin_studio.py"),
            home.appendingPathComponent("Desktop/codex-goated-skills/skills/minecraft-skin-studio/scripts/minecraft_skin_studio.py")
        ]

        for candidate in directCandidates where fileManager.fileExists(atPath: candidate.path) {
            return candidate
        }

        var searchRoot = Bundle.main.bundleURL
        for _ in 0..<7 {
            let candidate = searchRoot
                .appendingPathComponent("skills", isDirectory: true)
                .appendingPathComponent("minecraft-skin-studio", isDirectory: true)
                .appendingPathComponent("scripts", isDirectory: true)
                .appendingPathComponent("minecraft_skin_studio.py")
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            searchRoot.deleteLastPathComponent()
        }

        throw Error(message: "Couldn’t find minecraft_skin_studio.py. Install the skill first.", output: "")
    }

    private func resolveUVURL() throws -> URL {
        let candidates = [
            "/opt/homebrew/bin/uv",
            "/usr/local/bin/uv",
            environment["UV_BIN"] ?? ""
        ].filter { !$0.isEmpty }

        for candidate in candidates {
            let url = URL(fileURLWithPath: candidate)
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
        }

        throw Error(message: "uv is required but was not found on this Mac.", output: "")
    }

    private func mergedEnvironment(apiKey: String?, uvURL: URL) -> [String: String] {
        var env = environment
        let existingPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let uvDir = uvURL.deletingLastPathComponent().path
        env["PATH"] = ([uvDir] + existingPath.components(separatedBy: ":"))
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { acc, part in
                if !acc.contains(part) { acc.append(part) }
            }
            .joined(separator: ":")
        env["UV_BIN"] = uvURL.path
        if let apiKey, !apiKey.isEmpty {
            env["OPENAI_API_KEY"] = apiKey
        }
        return env
    }

    private func parse(output: String) -> SkinStudioResult {
        var result = SkinStudioResult(outputText: output)
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            if let value = strip(prefix: "Draft raw: ", from: line) {
                result.rawURL = URL(fileURLWithPath: value)
            } else if let value = strip(prefix: "Skin PNG: ", from: line) {
                result.skinURL = URL(fileURLWithPath: value)
            } else if let value = strip(prefix: "Preview: ", from: line) {
                result.previewURL = URL(fileURLWithPath: value)
            } else if let value = strip(prefix: "Launcher file: ", from: line) {
                result.launcherFileURL = URL(fileURLWithPath: value)
            } else if let value = strip(prefix: "Registered launcher skin id: ", from: line) {
                result.registeredSkinID = value
            }
        }

        return result
    }

    private func strip(prefix: String, from line: String) -> String? {
        guard line.hasPrefix(prefix) else { return nil }
        return String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
