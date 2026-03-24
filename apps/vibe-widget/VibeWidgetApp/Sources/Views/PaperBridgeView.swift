import SwiftUI

struct PaperBridgeView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                overview
                promptComposer
                setupCard
                latestRunCard
            }
            .padding(.bottom, 4)
        }
        .scrollIndicators(.hidden)
    }

    private var overview: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GitHub to Overleaf")
                            .font(.title2.weight(.bold))
                        Text("Trigger a GitHub Actions workflow from the menu bar, write LaTeX from a prompt, sync the sources to Overleaf, and keep the latest artifact one click away.")
                            .foregroundStyle(.secondary)
                        Text(model.paperBridgeStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 10) {
                        PaperBridgeStateBadge(label: model.paperBridgeRunLabel, run: model.latestPaperBridgeRun)

                        HStack(spacing: 10) {
                            Button("Refresh") {
                                Task { await model.refreshPaperBridgeStatus() }
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.isRefreshingPaperBridge)

                            Button("Actions") {
                                model.openPaperBridgeActions()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!model.settings.hasPaperBridgeConfiguration)
                        }
                    }
                }
            }
        }
    }

    private var promptComposer: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("Prompt dispatcher")
                    .font(.headline)

                TextEditor(text: $model.paperBridgePrompt)
                    .font(.system(.title3, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)

                HStack(spacing: 10) {
                    Button(model.isDispatchingPaperBridge ? "Dispatching..." : "Run On GitHub") {
                        model.runPaperBridgePrompt()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isDispatchingPaperBridge)

                    Button("Overleaf") {
                        model.openPaperBridgeOverleafProject()
                    }
                    .buttonStyle(.bordered)

                    if model.latestPaperBridgeArtifact != nil {
                        Button("Download Artifact") {
                            model.downloadPaperBridgeArtifact()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var setupCard: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                Text("Setup")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("GitHub owner", text: $model.settings.paperRepositoryOwner)
                        TextField("Repository", text: $model.settings.paperRepositoryName)
                    }

                    HStack(spacing: 12) {
                        TextField("Workflow file", text: $model.settings.paperWorkflowIdentifier)
                        TextField("Branch or tag", text: $model.settings.paperRepositoryRef)
                    }

                    HStack(spacing: 12) {
                        TextField("Overleaf project ID", text: $model.settings.paperOverleafProjectID)
                        TextField("Artifact name", text: $model.settings.paperArtifactName)
                    }

                    HStack(spacing: 12) {
                        TextField("Main TeX path", text: $model.settings.paperMainTeXPath)
                        TextField("GitHub token Keychain service", text: $model.settings.githubTokenServiceName)
                    }
                }
                .textFieldStyle(.roundedBorder)

                HStack(spacing: 12) {
                    SecureField("Paste GitHub token", text: $model.paperBridgeTokenInput)
                        .textFieldStyle(.roundedBorder)

                    Button(model.hasSavedGitHubToken ? "Update Token" : "Save Token") {
                        model.savePaperBridgeGitHubToken()
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack(spacing: 10) {
                    Button("Save Settings") {
                        model.persistSettings()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Repo Secrets") {
                        model.openPaperBridgeSecrets()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!model.settings.hasPaperBridgeConfiguration)

                    Button("Copy Workflow") {
                        model.copyPaperBridgeWorkflowTemplate()
                    }
                    .buttonStyle(.bordered)

                    Button("Copy Script") {
                        model.copyPaperBridgePromptScriptTemplate()
                    }
                    .buttonStyle(.bordered)

                    Button("Copy Secrets") {
                        model.copyPaperBridgeSecretsChecklist()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var latestRunCard: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Latest activity")
                        .font(.headline)

                    Spacer()

                    if let run = model.latestPaperBridgeRun {
                        PaperBridgeStateBadge(label: run.stateLabel, run: run)
                    }
                }

                if let latestRun = model.latestPaperBridgeRun {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(latestRun.displayTitle)
                            .font(.title3.weight(.bold))

                        Text("\(model.settings.paperRepositorySlug) • \(latestRun.branch.isEmpty ? model.settings.paperRepositoryRef : latestRun.branch)")
                            .foregroundStyle(.secondary)

                        Text("Started \(latestRun.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Button("Open Run") {
                                model.openPaperBridgeLatestRun()
                            }
                            .buttonStyle(.borderedProminent)

                            if model.latestPaperBridgeArtifact != nil {
                                Button("Save Artifact Zip") {
                                    model.downloadPaperBridgeArtifact()
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        if latestRun.artifacts.isEmpty {
                            Text("No artifact yet. If the run is still active, refresh after it finishes.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(latestRun.artifacts) { artifact in
                                PaperBridgeArtifactRow(artifact: artifact)
                            }
                        }
                    }
                } else {
                    Text("No GitHub Actions runs yet. Save the repo settings, add the workflow to your repo, and dispatch your first prompt.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PaperBridgeArtifactRow: View {
    let artifact: PaperBridgeArtifact

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: artifact.expired ? "archivebox" : "archivebox.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(artifact.expired ? Color.secondary : Color.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(artifact.name)
                    .font(.subheadline.weight(.bold))
                Text("\(artifact.sizeLabel) • \(artifact.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(artifact.expired ? "Expired" : "Ready")
                .font(.caption.weight(.bold))
                .foregroundStyle(artifact.expired ? .orange : .green)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private struct PaperBridgeStateBadge: View {
    let label: String
    let run: PaperBridgeRun?

    var body: some View {
        Text(label)
            .font(.caption.weight(.black))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule().fill(color.opacity(0.18)))
            .foregroundStyle(color)
    }

    private var color: Color {
        guard let run else { return .orange }
        if !run.isFinished { return .orange }

        switch run.conclusion {
        case "success":
            return .green
        case "failure":
            return .red
        case "cancelled":
            return .orange
        default:
            return .secondary
        }
    }
}
