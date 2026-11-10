import SwiftUI

struct FullScreenOverlayView: View {
    let completedPhase: TimerPhase
    @ObservedObject var languageManager: LanguageManager

    private var title: String {
        languageManager.text(completedPhase == .work ? .workCompleteTitle : .breakCompleteTitle)
    }

    private var subtitle: String {
        languageManager.text(completedPhase == .work ? .workCompleteSubtitle : .breakCompleteSubtitle)
    }

    private var accentColor: Color {
        completedPhase == .work ? .orange : .green
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: completedPhase == .work ? "cup.and.saucer.fill" : "flame.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(.system(size: 42, weight: .bold))

                Text(subtitle)
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(languageManager.text(.dismissOverlay))
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
