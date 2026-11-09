import SwiftUI

private let appVersion = "1.1.0"

struct PopoverView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var showSettings = false

    private var phaseColor: Color {
        timerManager.phase == .work ? .red : .green
    }

    var body: some View {
        VStack(spacing: 16) {
            // Phase label
            Text(timerManager.phase == .work ? "工作時間" : "休息時間")
                .font(.headline)
                .foregroundStyle(phaseColor)

            // Progress ring + time display
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

            // Control buttons
            HStack(spacing: 12) {
                if timerManager.state == .running {
                    Button("暫停") { timerManager.pause() }
                        .buttonStyle(.bordered)
                } else {
                    Button("開始") { timerManager.start() }
                        .buttonStyle(.borderedProminent)
                        .tint(phaseColor)
                }

                Button("重置") { timerManager.reset() }
                    .buttonStyle(.bordered)

                let nextPhase: TimerPhase = timerManager.phase == .work ? .shortBreak : .work
                Button(timerManager.phase == .work ? "休息" : "工作") {
                    timerManager.switchPhase(to: nextPhase)
                    timerManager.start()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            // Settings toggle + Quit
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettings.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                        Text(showSettings ? "隱藏設定" : "設定")
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
                        Text("離開")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text("v\(appVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // Expandable settings panel
            if showSettings {
                SettingsView(timerManager: timerManager)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}
