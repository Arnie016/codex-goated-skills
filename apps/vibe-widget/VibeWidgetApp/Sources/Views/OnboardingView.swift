import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 18) {
                Text("VibeWidget")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundStyle(VibeTheme.primaryText)

                Text("Voice-first vibe control for your PartyBox, Spotify flow, and Apple Home lights.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(VibeTheme.secondaryText)
                    .frame(maxWidth: 520, alignment: .leading)

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Main flow", systemImage: "waveform.and.sparkles")
                            .foregroundStyle(VibeTheme.primaryText)
                        Text("Say or type things like \"dim bedroom lights and play rain sounds\" and let the app route the vibe.")
                            .foregroundStyle(VibeTheme.secondaryText)
                        Label("Output-aware", systemImage: "speaker.wave.3.fill")
                            .foregroundStyle(VibeTheme.primaryText)
                        Text("The dashboard always shows whether your PartyBox is already the active output or needs a native handoff.")
                            .foregroundStyle(VibeTheme.secondaryText)
                    }
                    .font(.headline)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GlassPanel {
                VStack(alignment: .leading, spacing: 18) {
                    Text("First Run Setup")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(VibeTheme.primaryText)

                    Picker("Apple Home", selection: $model.settings.selectedHomeName) {
                        if model.homes.isEmpty {
                            Text("My Home").tag("My Home")
                        } else {
                            ForEach(model.homes, id: \.id) { home in
                                Text(home.name).tag(home.name)
                            }
                        }
                    }

                    TextField("Default room", text: $model.settings.defaultRoomName)
                    TextField("Preferred speaker", text: $model.settings.preferredSpeakerName)
                    TextField("Spotify client ID", text: $model.settings.spotifyClientID)
                    TextField("OpenAI Keychain service", text: $model.settings.openAIKeyServiceName)

                    HStack(spacing: 12) {
                        Button("Request Permissions") {
                            model.requestSetupPermissions()
                        }
                        .buttonStyle(.bordered)

                        Button("Connect Spotify") {
                            model.beginSpotifyLogin()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    HStack(spacing: 10) {
                        PermissionDot(state: model.permissionSnapshot.microphone, label: "Mic")
                        PermissionDot(state: model.permissionSnapshot.speech, label: "Speech")
                        PermissionDot(state: model.permissionSnapshot.home, label: "Home")
                    }

                    Text(model.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(VibeTheme.secondaryText)

                    Button("Enter VibeWidget") {
                        model.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(width: 440)
        }
    }
}
