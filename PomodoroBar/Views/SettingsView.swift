import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var languageManager: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { timerManager.autoStart },
                set: { timerManager.autoStart = $0 }
            )) {
                Text(languageManager.text(.autoStartNext))
            }
            .toggleStyle(.switch)

            Divider()

            durationRow(
                label: languageManager.text(.workDuration),
                value: Binding(
                    get: { timerManager.workDuration },
                    set: { timerManager.workDuration = $0 }
                ),
                range: 1...60
            )

            durationRow(
                label: languageManager.text(.breakDuration),
                value: Binding(
                    get: { timerManager.breakDuration },
                    set: { timerManager.breakDuration = $0 }
                ),
                range: 1...30
            )

            Picker(languageManager.text(.language), selection: $languageManager.selection) {
                ForEach(LanguagePreference.allCases) { preference in
                    Text(
                        preference == .system
                            ? languageManager.text(.systemDefault)
                            : preference.nativeName
                    )
                    .tag(preference)
                }
            }
            .pickerStyle(.menu)
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
                "\(value.wrappedValue) \(languageManager.text(.minutes))",
                value: value,
                in: range
            )
        }
    }
}
