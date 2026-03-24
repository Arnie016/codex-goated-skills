import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            VibeBackdrop()

            Group {
                if model.settings.hasCompletedOnboarding {
                    DashboardView(model: model)
                } else {
                    OnboardingView(model: model)
                }
            }
            .padding(32)
            .frame(maxWidth: 1280, maxHeight: .infinity)
        }
        .sheet(isPresented: $model.isPanelPresented) {
            VibePanelView(model: model)
                .frame(minWidth: 720, minHeight: 560)
        }
        .task {
            await model.bootstrap()
        }
        .onOpenURL { model.handleIncomingURL($0) }
        .onChange(of: scenePhase) { _, newPhase in
            model.handleScenePhase(newPhase)
        }
    }
}
