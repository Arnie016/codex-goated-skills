import SwiftUI

struct SkillBarMenuIcon: View {
    let isBusy: Bool
    let installedCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: isBusy ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                .font(.system(size: 14, weight: .semibold))

            if installedCount > 0 {
                Circle()
                    .fill(Color.white)
                    .frame(width: 5, height: 5)
                    .offset(x: 2, y: -1)
            }
        }
        .frame(width: 18, height: 16)
    }
}
