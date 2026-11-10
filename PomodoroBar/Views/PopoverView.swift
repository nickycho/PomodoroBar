import SwiftUI

private let appVersion = "1.1.1"

struct PopoverView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var languageManager: LanguageManager
    var onSettingsVisibilityChange: ((Bool) -> Void)? = nil
    @State private var showSettings = false

    private var phaseColor: Color {
        timerManager.phase == .work ? .red : .green
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(languageManager.text(timerManager.phase == .work ? .workPhase : .breakPhase))
                .font(.headline)
                .foregroundStyle(phaseColor)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        phaseColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(timerManager.timeString)
                    .font(.system(size: 38, weight: .bold, design: .monospaced))
            }
            .frame(width: 150, height: 150)

            HStack(spacing: 12) {
                if timerManager.state == .running {
                    Button(languageManager.text(.pause)) { timerManager.pause() }
                        .buttonStyle(.bordered)
                } else {
                    Button(languageManager.text(.start)) { timerManager.start() }
                        .buttonStyle(.borderedProminent)
                        .tint(phaseColor)
                }

                Button(languageManager.text(.reset)) { timerManager.reset() }
                    .buttonStyle(.bordered)

                let nextPhase: TimerPhase = timerManager.phase == .work ? .shortBreak : .work
                let nextPhaseLabel: AppTextKey = timerManager.phase == .work ? .switchToBreak : .switchToWork
                Button(languageManager.text(nextPhaseLabel)) {
                    timerManager.switchPhase(to: nextPhase)
                    timerManager.start()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettings.toggle()
                        onSettingsVisibilityChange?(showSettings)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                        Text(languageManager.text(showSettings ? .hideSettings : .settings))
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                        Text(languageManager.text(.quit))
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text("v\(appVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if showSettings {
                SettingsView(timerManager: timerManager, languageManager: languageManager)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}
