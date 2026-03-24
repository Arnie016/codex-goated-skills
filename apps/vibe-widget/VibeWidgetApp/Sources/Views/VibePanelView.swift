import SwiftUI

struct VibePanelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Command composer")
                            .font(.headline)

                        TextEditor(text: $model.commandText)
                            .font(.system(.title3, design: .rounded))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)

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

                            Text("Room: \(plan.room ?? model.settings.defaultRoomName)")
                            Text("Lights: \(plan.light.action.rawValue.capitalized)")
                            Text("Music: \(plan.music.action.rawValue.capitalized)")
                            if !plan.seedArtists.isEmpty {
                                Text("Seed artists: \(plan.seedArtists.joined(separator: ", "))")
                            }
                            if !plan.excludedArtists.isEmpty {
                                Text("Avoid: \(plan.excludedArtists.joined(separator: ", "))")
                            }
                            if !plan.moodTags.isEmpty {
                                Text("Mood tags: \(plan.moodTags.joined(separator: " • "))")
                            }

                            HStack {
                                Button("Confirm And Run") {
                                    model.confirmParsedPlan()
                                }
                                .buttonStyle(.borderedProminent)

                                Text("Confidence \(Int(plan.confidence * 100))%")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Try saying")
                            .font(.headline)
                        Text("dim bedroom lights and play rain sounds")
                        Text("play something cool like Justin Bieber but not him")
                        Text("play new artists")
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}
