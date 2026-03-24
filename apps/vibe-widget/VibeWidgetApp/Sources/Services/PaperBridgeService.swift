import Foundation
import VibeWidgetCore

struct PaperBridgeService {
    enum ServiceError: LocalizedError {
        case missingGitHubToken
        case incompleteConfiguration
        case invalidResponse
        case httpFailure(statusCode: Int, message: String)
        case artifactUnavailable

        var errorDescription: String? {
            switch self {
            case .missingGitHubToken:
                return "Save a GitHub token in Keychain before dispatching workflows."
            case .incompleteConfiguration:
                return "Add the repository owner, repo, workflow file, and branch first."
            case .invalidResponse:
                return "GitHub returned a response I could not understand."
            case let .httpFailure(statusCode, message):
                if message.isEmpty {
                    return "GitHub request failed with status \(statusCode)."
                }
                return "GitHub request failed: \(message)"
            case .artifactUnavailable:
                return "The latest run does not have a downloadable artifact yet."
            }
        }
    }

    private let keychain = KeychainSecretStore()

    func hasSavedGitHubToken(serviceName: String) -> Bool {
        guard let token = try? keychain.read(service: serviceName) else { return false }
        return !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func saveGitHubToken(_ token: String, serviceName: String) throws {
        try keychain.write(service: serviceName, value: token)
    }

    func fetchWorkflowSnapshot(settings: AppSettings) async throws -> PaperBridgeWorkflowSnapshot {
        let token = try githubToken(for: settings)
        let runs = try await fetchRuns(settings: settings, token: token, perPage: 6)
        guard let latest = runs.first else {
            return PaperBridgeWorkflowSnapshot(recentRuns: [])
        }

        let latestArtifacts = try await fetchArtifacts(
            settings: settings,
            token: token,
            runID: latest.id
        )

        var enrichedRuns = runs
        enrichedRuns[0].artifacts = latestArtifacts
        return PaperBridgeWorkflowSnapshot(recentRuns: enrichedRuns)
    }

    func dispatchPrompt(prompt: String, settings: AppSettings) async throws -> PaperBridgeRun? {
        let token = try githubToken(for: settings)
        let path = "/repos/\(encodedPath(settings.paperRepositoryOwner))/\(encodedPath(settings.paperRepositoryName))/actions/workflows/\(encodedPath(settings.paperWorkflowIdentifier))/dispatches"

        let inputs: [String: String] = [
            "prompt": prompt,
            "root_tex": settings.paperMainTeXPath,
            "artifact_name": settings.paperArtifactName
        ]

        let body: [String: Any] = [
            "ref": settings.paperRepositoryRef,
            "inputs": inputs
        ]

        _ = try await sendGitHubRequest(
            path: path,
            method: "POST",
            token: token,
            body: body
        )

        let startedAt = Date()
        for attempt in 0..<5 {
            if attempt > 0 {
                try await Task.sleep(for: .seconds(2))
            }

            let snapshot = try await fetchWorkflowSnapshot(settings: settings)
            guard let latestRun = snapshot.latestRun else { continue }

            if latestRun.createdAt >= startedAt.addingTimeInterval(-20) {
                return latestRun
            }
        }

        return try await fetchWorkflowSnapshot(settings: settings).latestRun
    }

    func downloadArtifact(
        _ artifact: PaperBridgeArtifact,
        settings: AppSettings,
        destinationURL: URL
    ) async throws {
        let token = try githubToken(for: settings)

        var request = URLRequest(url: artifact.archiveDownloadURL)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw ServiceError.httpFailure(
                statusCode: http.statusCode,
                message: messageFromGitHubResponse(data)
            )
        }

        try data.write(to: destinationURL, options: .atomic)
    }

    func workflowTemplate(settings: AppSettings) -> String {
        let artifactName = escapedYAMLString(settings.paperArtifactName)
        let rootTeX = escapedYAMLString(settings.paperMainTeXPath)

        return """
        name: Overleaf Bridge

        on:
          workflow_dispatch:
            inputs:
              prompt:
                description: "What should go into the LaTeX document?"
                required: true
                type: string
              root_tex:
                description: "Main TeX file to build"
                required: false
                default: "\(rootTeX)"
                type: string
              artifact_name:
                description: "Artifact name for the compiled PDF"
                required: false
                default: "\(artifactName)"
                type: string

        jobs:
          render-and-sync:
            runs-on: ubuntu-latest
            permissions:
              contents: read

            steps:
              - name: Check out repository
                uses: actions/checkout@v4

              - name: Write LaTeX from the prompt
                env:
                  PAPER_PROMPT: ${{ github.event.inputs.prompt }}
                  PAPER_ROOT_TEX: ${{ github.event.inputs.root_tex || '\(rootTeX)' }}
                run: python3 scripts/prompt_to_latex.py

              - name: Build PDF
                uses: xu-cheng/latex-action@v3
                with:
                  root_file: ${{ github.event.inputs.root_tex || '\(rootTeX)' }}

              - name: Resolve PDF path
                id: output
                shell: bash
                run: |
                  ROOT_TEX="${{ github.event.inputs.root_tex || '\(rootTeX)' }}"
                  echo "pdf_path=${ROOT_TEX%.tex}.pdf" >> "$GITHUB_OUTPUT"

              - name: Upload PDF artifact
                uses: actions/upload-artifact@v4
                with:
                  name: ${{ github.event.inputs.artifact_name || '\(artifactName)' }}
                  path: ${{ steps.output.outputs.pdf_path }}

              - name: Sync source to Overleaf via Git
                env:
                  OVERLEAF_PROJECT_ID: ${{ secrets.OVERLEAF_PROJECT_ID }}
                  OVERLEAF_GIT_TOKEN: ${{ secrets.OVERLEAF_GIT_TOKEN }}
                run: |
                  git clone "https://git:${OVERLEAF_GIT_TOKEN}@git.overleaf.com/${OVERLEAF_PROJECT_ID}" overleaf
                  rsync -av --delete --exclude ".git" ./ overleaf/
                  cd overleaf
                  git config user.name "github-actions[bot]"
                  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
                  git add -A
                  git commit -m "Sync LaTeX from GitHub Actions" || echo "No changes to commit"
                  git push origin HEAD
        """
    }

    func promptScriptTemplate(settings: AppSettings) -> String {
        let rootTeX = settings.paperMainTeXPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "main.tex"
            : settings.paperMainTeXPath.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        import os
        from pathlib import Path

        PROMPT = os.environ.get("PAPER_PROMPT", "").strip()
        ROOT_TEX = Path(os.environ.get("PAPER_ROOT_TEX", "\(rootTeX)"))

        def latex_escape(value: str) -> str:
            replacements = {
                "\\\\": r"\\textbackslash{}",
                "&": r"\\&",
                "%": r"\\%",
                "$": r"\\$",
                "#": r"\\#",
                "_": r"\\_",
                "{": r"\\{",
                "}": r"\\}",
                "~": r"\\textasciitilde{}",
                "^": r"\\textasciicircum{}",
            }
            return "".join(replacements.get(character, character) for character in value)

        body = latex_escape(PROMPT or "Describe the paper you want here.")

        document = f\"\"\"\\\\documentclass[11pt]{{article}}
        \\\\usepackage[margin=1in]{{geometry}}
        \\\\usepackage{{hyperref}}
        \\\\title{{Prompt Draft}}
        \\\\author{{GitHub to Overleaf Bridge}}
        \\\\date{{\\\\today}}

        \\\\begin{{document}}
        \\\\maketitle

        \\\\section*{{Prompt}}
        {body}

        \\\\end{{document}}
        \"\"\"

        ROOT_TEX.parent.mkdir(parents=True, exist_ok=True)
        ROOT_TEX.write_text(document, encoding="utf-8")
        print(f"Wrote {{ROOT_TEX}}")
        """
    }

    func secretsChecklist(settings: AppSettings) -> String {
        """
        GitHub repository secrets to add for \(settings.paperRepositorySlug):

        1. OVERLEAF_PROJECT_ID
           Your Overleaf project ID from the project URL.

        2. OVERLEAF_GIT_TOKEN
           The Overleaf Git password/token used with the username `git`.

        Recommended files to add to the repo:
        - .github/workflows/\(settings.paperWorkflowIdentifier)
        - scripts/prompt_to_latex.py

        Workflow inputs expected by the menu bar app:
        - prompt
        - root_tex
        - artifact_name
        """
    }

    private func githubToken(for settings: AppSettings) throws -> String {
        guard settings.hasPaperBridgeConfiguration else {
            throw ServiceError.incompleteConfiguration
        }

        let token = try? keychain.read(service: settings.githubTokenServiceName)
        let trimmed = token?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            throw ServiceError.missingGitHubToken
        }
        return trimmed
    }

    private func fetchRuns(
        settings: AppSettings,
        token: String,
        perPage: Int
    ) async throws -> [PaperBridgeRun] {
        let path = "/repos/\(encodedPath(settings.paperRepositoryOwner))/\(encodedPath(settings.paperRepositoryName))/actions/workflows/\(encodedPath(settings.paperWorkflowIdentifier))/runs?per_page=\(perPage)"
        let data = try await sendGitHubRequest(path: path, method: "GET", token: token)
        let decoded = try JSONDecoder().decode(WorkflowRunsResponse.self, from: data)
        return decoded.workflowRuns.compactMap(PaperBridgeRun.init)
    }

    private func fetchArtifacts(
        settings: AppSettings,
        token: String,
        runID: Int
    ) async throws -> [PaperBridgeArtifact] {
        let path = "/repos/\(encodedPath(settings.paperRepositoryOwner))/\(encodedPath(settings.paperRepositoryName))/actions/runs/\(runID)/artifacts"
        let data = try await sendGitHubRequest(path: path, method: "GET", token: token)
        let decoded = try JSONDecoder().decode(ArtifactListResponse.self, from: data)
        return decoded.artifacts.compactMap(PaperBridgeArtifact.init)
    }

    private func sendGitHubRequest(
        path: String,
        method: String,
        token: String,
        body: [String: Any]? = nil
    ) async throws -> Data {
        guard let url = URL(string: "https://api.github.com\(path)") else {
            throw ServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw ServiceError.httpFailure(
                statusCode: http.statusCode,
                message: messageFromGitHubResponse(data)
            )
        }

        return data
    }

    private func messageFromGitHubResponse(_ data: Data) -> String {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = json["message"] as? String
        else {
            return ""
        }

        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let details = errors.compactMap { $0["message"] as? String }.joined(separator: ", ")
            if !details.isEmpty {
                return "\(message) (\(details))"
            }
        }

        return message
    }

    private func encodedPath(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }

    private func escapedYAMLString(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "\\\"")
    }
}

private struct WorkflowRunsResponse: Decodable {
    let workflowRuns: [WorkflowRunResponse]

    private enum CodingKeys: String, CodingKey {
        case workflowRuns = "workflow_runs"
    }
}

private struct WorkflowRunResponse: Decodable {
    let id: Int
    let runNumber: Int
    let name: String?
    let displayTitle: String?
    let event: String?
    let status: String?
    let conclusion: String?
    let headBranch: String?
    let createdAt: String?
    let updatedAt: String?
    let htmlURL: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case runNumber = "run_number"
        case name
        case displayTitle = "display_title"
        case event
        case status
        case conclusion
        case headBranch = "head_branch"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case htmlURL = "html_url"
    }
}

private struct ArtifactListResponse: Decodable {
    let artifacts: [ArtifactResponse]
}

private struct ArtifactResponse: Decodable {
    let id: Int
    let name: String
    let sizeInBytes: Int
    let expired: Bool
    let createdAt: String?
    let archiveDownloadURL: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case sizeInBytes = "size_in_bytes"
        case expired
        case createdAt = "created_at"
        case archiveDownloadURL = "archive_download_url"
    }
}

private extension PaperBridgeRun {
    init?(_ response: WorkflowRunResponse) {
        guard
            let createdAt = GitHubDateParser.parse(response.createdAt),
            let updatedAt = GitHubDateParser.parse(response.updatedAt),
            let htmlURLString = response.htmlURL,
            let htmlURL = URL(string: htmlURLString)
        else {
            return nil
        }

        self.init(
            id: response.id,
            runNumber: response.runNumber,
            workflowName: response.name ?? "Overleaf Bridge",
            displayTitle: response.displayTitle ?? "Manual dispatch",
            event: response.event ?? "workflow_dispatch",
            status: response.status ?? "queued",
            conclusion: response.conclusion,
            branch: response.headBranch ?? "",
            createdAt: createdAt,
            updatedAt: updatedAt,
            htmlURL: htmlURL,
            artifacts: []
        )
    }
}

private extension PaperBridgeArtifact {
    init?(_ response: ArtifactResponse) {
        guard
            let createdAt = GitHubDateParser.parse(response.createdAt),
            let archiveDownloadURLString = response.archiveDownloadURL,
            let archiveDownloadURL = URL(string: archiveDownloadURLString)
        else {
            return nil
        }

        self.init(
            id: response.id,
            name: response.name,
            sizeInBytes: response.sizeInBytes,
            expired: response.expired,
            createdAt: createdAt,
            archiveDownloadURL: archiveDownloadURL
        )
    }
}

private enum GitHubDateParser {
    static func parse(_ rawValue: String?) -> Date? {
        guard let rawValue else { return nil }

        let formatters = [
            formatter(withFractionalSeconds: true),
            formatter(withFractionalSeconds: false)
        ]

        for formatter in formatters {
            if let date = formatter.date(from: rawValue) {
                return date
            }
        }

        return nil
    }

    private static func formatter(withFractionalSeconds: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = withFractionalSeconds
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter
    }
}
