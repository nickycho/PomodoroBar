import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { timerManager.autoStart },
                set: { timerManager.autoStart = $0 }
            )) {
                Text("自動開始下一輪")
            }
            .toggleStyle(.switch)

            Divider()

            durationRow(
                label: "工作時間",
                value: Binding(
                    get: { timerManager.workDuration },
                    set: { timerManager.workDuration = $0 }
                ),
                range: 1...60
            )

            durationRow(
                label: "休息時間",
                value: Binding(
                    get: { timerManager.breakDuration },
                    set: { timerManager.breakDuration = $0 }
                ),
                range: 1...30
            )
        }
        .padding(.horizontal, 4)
        .font(.callout)
    }

    private func durationRow(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            Stepper(
                "\(value.wrappedValue) 分鐘",
                value: value,
                in: range
            )
        }
    }
}
