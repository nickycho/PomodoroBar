import SwiftUI

struct FullScreenOverlayView: View {
    let completedPhase: TimerPhase

    private var title: String {
        completedPhase == .work ? "工作時間結束！" : "休息時間結束！"
    }

    private var subtitle: String {
        completedPhase == .work ? "好好休息一下" : "準備開始工作"
    }

    private var accentColor: Color {
        completedPhase == .work ? .orange : .green
    }

    var body: some View {
        ZStack {
            // Full-screen blur background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Center card
            VStack(spacing: 16) {
                Image(systemName: completedPhase == .work ? "cup.and.saucer.fill" : "flame.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(.system(size: 42, weight: .bold))

                Text(subtitle)
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("點擊任意處或按任意鍵繼續")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 12)
            }
            .padding(56)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            .shadow(color: .black.opacity(0.15), radius: 30, y: 10)
        }
    }
}
