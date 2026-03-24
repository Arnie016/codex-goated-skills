import SwiftUI

struct VibePanelView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            VibeBackdrop(secondaryOnly: true)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AI Vibe Panel")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(VibeTheme.primaryText)
                        Text("Type or speak a command, then let the parser turn it into lighting plus music actions.")
                            .foregroundStyle(VibeTheme.secondaryText)
                    }
                    Spacer()
                    Button("Done") { dismiss() }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        TextEditor(text: $model.commandText)
                            .font(.system(.title3, design: .rounded))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 140)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(VibeTheme.panelRaised)
                            )
                            .foregroundStyle(VibeTheme.primaryText)

                        HStack {
                            Button(model.isListening ? "Stop Listening" : "Push To Talk") {
                                model.toggleVoiceCapture()
                            }
                            .buttonStyle(.bordered)

                            Button(model.isProcessing ? "Working..." : "Run Command") {
                                Task { await model.runCommand() }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.isProcessing)
                        }
                    }
                }

                if let plan = model.parsedPlan {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Parsed plan")
                                .font(.headline)
                                .foregroundStyle(VibeTheme.primaryText)

                            Text("Room: \(plan.room ?? model.settings.defaultRoomName)")
                                .foregroundStyle(VibeTheme.secondaryText)
                            Text("Lights: \(plan.light.action.rawValue.capitalized)")
                                .foregroundStyle(VibeTheme.secondaryText)
                            Text("Music: \(plan.music.action.rawValue.capitalized)")
                                .foregroundStyle(VibeTheme.secondaryText)
                            if !plan.seedArtists.isEmpty {
                                Text("Seed artists: \(plan.seedArtists.joined(separator: ", "))")
                                    .foregroundStyle(VibeTheme.secondaryText)
                            }
                            if !plan.excludedArtists.isEmpty {
                                Text("Avoid: \(plan.excludedArtists.joined(separator: ", "))")
                                    .foregroundStyle(VibeTheme.secondaryText)
                            }
                            if !plan.moodTags.isEmpty {
                                Text("Mood tags: \(plan.moodTags.joined(separator: " • "))")
                                    .foregroundStyle(VibeTheme.secondaryText)
                            }

                            HStack {
                                Button("Confirm And Run") {
                                    model.confirmParsedPlan()
                                }
                                .buttonStyle(.borderedProminent)

                                Text("Confidence \(Int(plan.confidence * 100))%")
                                    .foregroundStyle(VibeTheme.secondaryText)
                            }
                        }
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Try saying")
                            .font(.headline)
                            .foregroundStyle(VibeTheme.primaryText)
                        Text("dim bedroom lights and play rain sounds")
                            .foregroundStyle(VibeTheme.secondaryText)
                        Text("play something cool like Justin Bieber but not him")
                            .foregroundStyle(VibeTheme.secondaryText)
                        Text("play new artists")
                            .foregroundStyle(VibeTheme.secondaryText)
                    }
                }

                Spacer()
            }
            .padding(26)
        }
    }
}
