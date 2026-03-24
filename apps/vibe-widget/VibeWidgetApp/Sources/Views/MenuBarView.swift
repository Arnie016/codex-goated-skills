import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsPaperSetup = false
    private let mindDeclutterTint = Color(red: 0.48, green: 0.71, blue: 0.84)

    var body: some View {
        ZStack {
            VibeBackdrop(secondaryOnly: true)

            TimelineView(.periodic(from: .now, by: 30)) { _ in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        header
                        mindDeclutterPanel
                        paperBridgePanel

                        if showsPaperSetup {
                            paperBridgeSetupPanel
                        }
                    }
                    .padding(10)
                    .frame(width: 368)
                }
            }
        }
        .task {
            await model.bootstrap()
        }
        .onChange(of: scenePhase) { _, newPhase in
            model.handleScenePhase(newPhase)
        }
        .onOpenURL { url in
            model.handleIncomingURL(url)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("VibeWidget")
                    .font(.system(size: 16, weight: .semibold, design: .default))

                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                ScoutToolbarButton(symbol: model.mindDeclutterToolbarSymbolName) {
                    model.toggleMindDeclutterSession()
                }

                if model.isRefreshingDiscovery || model.isRefreshingPaperBridge || model.isDispatchingPaperBridge {
                    ScoutToolbarProgress()
                }

                ScoutToolbarButton(
                    symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                    isDisabled: !model.settings.hasCompletedOnboarding && !model.settings.hasPaperBridgeConfiguration
                ) {
                    if model.settings.hasPaperBridgeConfiguration {
                        Task { await model.refreshPaperBridgeStatus() }
                    } else {
                        model.performQuickAction(.refreshRecommendations)
                    }
                }

                Menu {
                    Button(model.isMindDeclutterActive ? "End Declutter Session" : "Start Declutter Session") {
                        model.toggleMindDeclutterSession()
                    }

                    if model.mindDeclutterPlan.suggestedFocusTask != nil {
                        Button("Use Suggested Focus") {
                            model.useSuggestedMindDeclutterFocus()
                        }
                    }

                    if model.mindDeclutterFocusTask != nil {
                        Button("Copy Next Step") {
                            model.copyMindDeclutterFocus()
                        }
                    }

                    Divider()

                    Button(showsPaperSetup ? "Hide Paper Setup" : "Paper Setup") {
                        showsPaperSetup.toggle()
                    }

                    if model.settings.hasPaperBridgeConfiguration {
                        Button("Paper Actions") {
                            model.openPaperBridgeActions()
                        }

                        Button("Open Overleaf") {
                            model.openPaperBridgeOverleafProject()
                        }

                        Divider()
                    }

                    Button("Quit") {
                        NSApp.terminate(nil)
                    }
                } label: {
                    ScoutToolbarGlyph(symbol: "slider.horizontal.3")
                }
                .menuStyle(.borderlessButton)
            }
        }
    }

    private var mindDeclutterPanel: some View {
        ScoutCompactPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    ScoutPanelHeading(
                        symbol: model.isMindDeclutterActive ? "bell.slash.fill" : "bell.slash",
                        title: "Mind Declutter",
                        subtitle: model.mindDeclutterPanelSubtitle,
                        tint: mindDeclutterTint
                    )

                    Spacer(minLength: 0)

                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        ScoutMoodPill(
                            text: model.mindDeclutterSessionLabel(at: context.date).uppercased(),
                            tint: mindDeclutterTint
                        )
                    }
                }

                HStack(spacing: 8) {
                    MindDeclutterMetricPill(
                        label: "Loops",
                        value: "\(model.mindDeclutterPlan.itemCount)",
                        tint: mindDeclutterTint
                    )

                    MindDeclutterMetricPill(
                        label: "Blockers",
                        value: "\(model.mindDeclutterBlockerCount)",
                        tint: Color(red: 0.79, green: 0.48, blue: 0.40)
                    )

                    MindDeclutterMetricPill(
                        label: "Parked",
                        value: "\(model.mindDeclutterParkingCount)",
                        tint: Color(red: 0.72, green: 0.57, blue: 0.33)
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Brain Dump")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        if model.settings.mindDeclutterInboxText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Drop the tasks, worries, blockers, and side quests here. Use one line per item for the cleanest declutter.")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: mindDeclutterInboxBinding)
                            .font(.system(.body, design: .rounded))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 92)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                }

                if hasDistinctMindDeclutterSuggestion,
                   let suggestion = model.mindDeclutterPlan.suggestedFocusTask {
                    MindDeclutterSuggestionCard(
                        suggestion: suggestion,
                        tint: mindDeclutterTint
                    ) {
                        model.useSuggestedMindDeclutterFocus()
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Now")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("Pin the one next step you want to hold", text: mindDeclutterFocusBinding)
                        .textFieldStyle(.roundedBorder)

                    MindDeclutterFocusCard(focusTask: model.mindDeclutterFocusTask)
                }

                if !model.mindDeclutterBlockers.isEmpty {
                    MindDeclutterListSection(
                        title: "Blockers",
                        items: model.mindDeclutterBlockers,
                        overflowCount: 0,
                        tint: Color(red: 0.79, green: 0.48, blue: 0.40)
                    )
                }

                if !model.mindDeclutterParkingLot.isEmpty || model.mindDeclutterOverflowCount > 0 {
                    MindDeclutterListSection(
                        title: "Parking Lot",
                        items: model.mindDeclutterParkingLot,
                        overflowCount: model.mindDeclutterOverflowCount,
                        tint: mindDeclutterTint
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Picker("Session", selection: sessionMinutesBinding) {
                        Text("15m").tag(15)
                        Text("30m").tag(30)
                        Text("60m").tag(60)
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 8) {
                        Button(model.isMindDeclutterActive ? "Restart" : "Start") {
                            model.startMindDeclutterSession()
                        }
                        .buttonStyle(.borderedProminent)

                        if model.isMindDeclutterActive {
                            Button("End") {
                                model.endMindDeclutterSession()
                            }
                            .buttonStyle(.bordered)
                        }

                        Button("Suggest") {
                            model.useSuggestedMindDeclutterFocus()
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.mindDeclutterPlan.suggestedFocusTask == nil)
                    }

                    HStack(spacing: 8) {
                        Button("Copy Next") {
                            model.copyMindDeclutterFocus()
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.mindDeclutterFocusTask == nil)

                        Button("Copy Brief") {
                            model.copyMindDeclutterBrief()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!model.hasMindDeclutterDraft && model.mindDeclutterFocusTask == nil)

                        Button("Clear") {
                            model.clearMindDeclutterCapture()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!model.hasMindDeclutterDraft && model.mindDeclutterFocusTask == nil && !model.isMindDeclutterActive)
                    }
                }

                Text(model.mindDeclutterHelperText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var paperBridgePanel: some View {
        ScoutCompactPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    ScoutPanelHeading(
                        symbol: "doc.badge.gearshape",
                        title: "Paper Bridge",
                        subtitle: "Run GitHub prompts, sync LaTeX to Overleaf, and keep the latest PDF close.",
                        tint: Color(red: 0.75, green: 0.45, blue: 0.18)
                    )

                    Spacer(minLength: 0)

                    ScoutMoodPill(
                        text: model.paperBridgeShortSummary.uppercased(),
                        tint: Color(red: 0.75, green: 0.45, blue: 0.18)
                    )
                }

                TextEditor(text: $model.paperBridgePrompt)
                    .font(.system(.body, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 74)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )

                HStack(spacing: 8) {
                    Button(model.isDispatchingPaperBridge ? "Working..." : "Run Prompt") {
                        model.runPaperBridgePrompt()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isDispatchingPaperBridge)

                    Button("Status") {
                        Task { await model.refreshPaperBridgeStatus() }
                    }
                    .buttonStyle(.bordered)

                    if model.latestPaperBridgeArtifact != nil {
                        Button("Download") {
                            model.downloadPaperBridgeArtifact()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button(showsPaperSetup ? "Hide Setup" : "Setup") {
                            showsPaperSetup.toggle()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.paperBridgeStatusDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(model.paperBridgeStatusMessage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var paperBridgeSetupPanel: some View {
        ScoutCompactPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GitHub -> Overleaf Setup")
                            .font(.headline.weight(.semibold))

                        Text("Save the repo details and GitHub token, then copy the workflow and helper script into your paper repo.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    Spacer(minLength: 0)

                    Button("Hide") {
                        showsPaperSetup = false
                    }
                    .buttonStyle(.borderless)
                }

                Group {
                    HStack(spacing: 8) {
                        TextField("Owner", text: $model.settings.paperRepositoryOwner)
                        TextField("Repo", text: $model.settings.paperRepositoryName)
                    }

                    HStack(spacing: 8) {
                        TextField("Workflow file", text: $model.settings.paperWorkflowIdentifier)
                        TextField("Branch", text: $model.settings.paperRepositoryRef)
                    }

                    HStack(spacing: 8) {
                        TextField("Overleaf project ID", text: $model.settings.paperOverleafProjectID)
                        TextField("Artifact", text: $model.settings.paperArtifactName)
                    }

                    HStack(spacing: 8) {
                        TextField("Main TeX", text: $model.settings.paperMainTeXPath)
                        TextField("Token service", text: $model.settings.githubTokenServiceName)
                    }

                    SecureField("Paste GitHub token", text: $model.paperBridgeTokenInput)
                }
                .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    Button(model.hasSavedGitHubToken ? "Update Token" : "Save Token") {
                        model.savePaperBridgeGitHubToken()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Save Settings") {
                        model.persistSettings()
                    }
                    .buttonStyle(.bordered)

                    Button("Copy Workflow") {
                        model.copyPaperBridgeWorkflowTemplate()
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 8) {
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

    private var subtitleText: String {
        if model.isMindDeclutterActive || model.hasMindDeclutterDraft {
            return model.mindDeclutterStatusLine
        }

        if model.settings.hasPaperBridgeConfiguration || model.hasSavedGitHubToken {
            return model.paperBridgeStatusDetail
        }

        return "Quiet the noisy tabs in your head, then launch the actual work."
    }

    private var mindDeclutterInboxBinding: Binding<String> {
        Binding(
            get: { model.settings.mindDeclutterInboxText },
            set: { model.updateMindDeclutterInbox($0) }
        )
    }

    private var mindDeclutterFocusBinding: Binding<String> {
        Binding(
            get: { model.settings.mindDeclutterFocusText },
            set: { model.updateMindDeclutterFocus($0) }
        )
    }

    private var sessionMinutesBinding: Binding<Int> {
        Binding(
            get: { model.mindDeclutterSessionMinutes },
            set: { model.setMindDeclutterSessionMinutes($0) }
        )
    }

    private var hasDistinctMindDeclutterSuggestion: Bool {
        guard let suggestion = model.mindDeclutterPlan.suggestedFocusTask else { return false }
        guard let focus = model.mindDeclutterFocusTask else { return true }
        return suggestion.localizedCaseInsensitiveCompare(focus) != .orderedSame
    }
}

private struct MindDeclutterFocusCard: View {
    let focusTask: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Resolved Next Step")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(focusTask ?? "Drop a few loose tasks above and I will help shrink them to one next move.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(focusTask == nil ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private struct MindDeclutterMetricPill: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.semibold))

            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }
}

private struct MindDeclutterSuggestionCard: View {
    let suggestion: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.14))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested Focus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(suggestion)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button("Use") {
                action()
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private struct MindDeclutterListSection: View {
    let title: String
    let items: [String]
    let overflowCount: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(tint)
                        .frame(width: 7, height: 7)
                        .padding(.top, 6)

                    Text(item)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if overflowCount > 0 {
                Text("+ \(overflowCount) more parked tab\(overflowCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}
