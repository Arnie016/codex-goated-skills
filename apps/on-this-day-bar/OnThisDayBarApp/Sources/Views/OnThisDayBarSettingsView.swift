import SwiftUI

struct OnThisDayBarSettingsView: View {
    @ObservedObject var model: OnThisDayBarAppModel

    var body: some View {
        ZStack {
            OnThisDayBackdrop()

            VStack(alignment: .leading, spacing: 12) {
                OnThisDayCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("On This Day Bar")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(OnThisDayPalette.primaryText)
                        Text("Keep the default view tight enough for the menu bar, but let it breathe when you want a deeper skim.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(OnThisDayPalette.secondaryText)
                    }
                }

                OnThisDayCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Defaults")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OnThisDayPalette.primaryText)

                        Picker("Start view", selection: $model.activeKind) {
                            ForEach(OnThisDayFeedKind.allCases) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        .pickerStyle(.menu)

                        Stepper(value: storyLimitBinding, in: 3...7) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Stories shown: \(model.storyLimit)")
                                    .foregroundStyle(OnThisDayPalette.primaryText)
                                Text("The menu bar popover works best between 3 and 7 visible cards.")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(OnThisDayPalette.secondaryText)
                            }
                        }
                    }
                }

                OnThisDayCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Source")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OnThisDayPalette.primaryText)
                        Text("Data comes from the official Wikimedia On This Day feed, with cached fallback if the live request fails.")
                            .font(.system(size: 11))
                            .foregroundStyle(OnThisDayPalette.secondaryText)

                        HStack(spacing: 8) {
                            Button("Refresh Today") {
                                model.jumpToday()
                            }
                            .buttonStyle(OnThisDayPrimaryButtonStyle())

                            Button("Open API Docs") {
                                model.openDocs()
                            }
                            .buttonStyle(OnThisDaySecondaryButtonStyle())
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var storyLimitBinding: Binding<Int> {
        Binding(
            get: { model.storyLimit },
            set: { model.storyLimit = $0 }
        )
    }
}
