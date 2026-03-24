import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            VibeBackdrop()

            ContextStudioView(model: model)
                .padding(32)
        }
    }
}
