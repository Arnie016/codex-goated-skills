import SwiftUI

struct TradingArchiveBarSettingsView: View {
    @ObservedObject var model: TradingArchiveBarAppModel

    var body: some View {
        ZStack {
            TradingArchiveBackdrop()

            VStack(alignment: .leading, spacing: 14) {
                Text("Trading Archive Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(TradingArchivePalette.primaryText)

                Text("Paste one RSS or Atom feed URL per line. The archive keeps recent stories locally so the menu bar stays useful even when a feed is flaky.")
                    .font(.system(size: 12))
                    .foregroundStyle(TradingArchivePalette.secondaryText)

                TextEditor(text: $model.sourcesText)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(TradingArchivePalette.border, lineWidth: 1)
                            )
                    )

                Stepper(value: storyLimitBinding, in: 10...80, step: 5) {
                    Text("Stories shown in the popover: \(model.storyLimit)")
                        .font(.system(size: 12))
                        .foregroundStyle(TradingArchivePalette.primaryText)
                }

                HStack(spacing: 8) {
                    Button("Refresh Now") {
                        Task { await model.refresh(force: true) }
                    }
                    .buttonStyle(TradingArchivePrimaryButtonStyle())

                    Text("\(model.parsedSourceURLs.count) valid feeds detected")
                        .font(.system(size: 11))
                        .foregroundStyle(TradingArchivePalette.secondaryText)
                }

                Spacer()
            }
            .padding(18)
        }
    }

    private var storyLimitBinding: Binding<Int> {
        Binding(
            get: { model.storyLimit },
            set: { model.storyLimit = $0 }
        )
    }
}
