import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"

    var id: String { rawValue }

    static func resolve(preferredLanguages: [String]) -> AppLanguage {
        for preferredLanguage in preferredLanguages {
            let normalized = preferredLanguage
                .replacingOccurrences(of: "_", with: "-")
                .lowercased()
            guard let languageCode = normalized.split(separator: "-").first else { continue }

            switch languageCode {
            case "en": return .english
            case "zh": return .traditionalChinese
            case "ja": return .japanese
            case "ko": return .korean
            default: continue
            }
        }

        return .english
    }
}

enum LanguagePreference: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .system: return ""
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    func resolve(preferredLanguages: [String]) -> AppLanguage {
        switch self {
        case .system:
            return AppLanguage.resolve(preferredLanguages: preferredLanguages)
        case .english:
            return .english
        case .traditionalChinese:
            return .traditionalChinese
        case .japanese:
            return .japanese
        case .korean:
            return .korean
        }
    }
}

enum AppTextKey: Hashable {
    case workPhase
    case breakPhase
    case start
    case pause
    case reset
    case switchToBreak
    case switchToWork
    case settings
    case hideSettings
    case quit
    case autoStartNext
    case workDuration
    case breakDuration
    case minutes
    case language
    case systemDefault
    case workCompleteTitle
    case breakCompleteTitle
    case workCompleteSubtitle
    case breakCompleteSubtitle
    case dismissOverlay
}

final class LanguageManager: ObservableObject {
    private static let preferenceKey = "languagePreference"

    private let defaults: UserDefaults
    private let preferredLanguages: [String]

    @Published var selection: LanguagePreference {
        didSet {
            defaults.set(selection.rawValue, forKey: Self.preferenceKey)
        }
    }

    var currentLanguage: AppLanguage {
        selection.resolve(preferredLanguages: preferredLanguages)
    }

    init(
        defaults: UserDefaults = .standard,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) {
        self.defaults = defaults
        self.preferredLanguages = preferredLanguages
        let savedPreference = defaults.string(forKey: Self.preferenceKey)
            .flatMap(LanguagePreference.init(rawValue:))
        self.selection = savedPreference ?? .system
    }

    func text(_ key: AppTextKey) -> String {
        AppTranslations.values[currentLanguage]?[key]
            ?? AppTranslations.values[.english]?[key]
            ?? ""
    }
}

private enum AppTranslations {
    static let values: [AppLanguage: [AppTextKey: String]] = [
        .english: [
            .workPhase: "Work Session",
            .breakPhase: "Break",
            .start: "Start",
            .pause: "Pause",
            .reset: "Reset",
            .switchToBreak: "Break",
            .switchToWork: "Work",
            .settings: "Settings",
            .hideSettings: "Hide Settings",
            .quit: "Quit",
            .autoStartNext: "Automatically start the next session",
            .workDuration: "Work duration",
            .breakDuration: "Break duration",
            .minutes: "min",
            .language: "Language",
            .systemDefault: "System Default",
            .workCompleteTitle: "Work session complete!",
            .breakCompleteTitle: "Break complete!",
            .workCompleteSubtitle: "Take a well-deserved break.",
            .breakCompleteSubtitle: "Ready to focus?",
            .dismissOverlay: "Click or press any key to continue."
        ],
        .traditionalChinese: [
            .workPhase: "工作時間",
            .breakPhase: "休息時間",
            .start: "開始",
            .pause: "暫停",
            .reset: "重置",
            .switchToBreak: "休息",
            .switchToWork: "工作",
            .settings: "設定",
            .hideSettings: "隱藏設定",
            .quit: "離開",
            .autoStartNext: "自動開始下一輪",
            .workDuration: "工作時間",
            .breakDuration: "休息時間",
            .minutes: "分鐘",
            .language: "語言",
            .systemDefault: "跟隨系統",
            .workCompleteTitle: "工作時間結束！",
            .breakCompleteTitle: "休息時間結束！",
            .workCompleteSubtitle: "好好休息一下",
            .breakCompleteSubtitle: "準備開始工作",
            .dismissOverlay: "點擊任意處或按任意鍵繼續"
        ],
        .japanese: [
            .workPhase: "作業時間",
            .breakPhase: "休憩時間",
            .start: "開始",
            .pause: "一時停止",
            .reset: "リセット",
            .switchToBreak: "休憩",
            .switchToWork: "作業",
            .settings: "設定",
            .hideSettings: "設定を隠す",
            .quit: "終了",
            .autoStartNext: "次のセッションを自動開始",
            .workDuration: "作業時間",
            .breakDuration: "休憩時間",
            .minutes: "分",
            .language: "言語",
            .systemDefault: "システム設定に従う",
            .workCompleteTitle: "作業時間終了！",
            .breakCompleteTitle: "休憩時間終了！",
            .workCompleteSubtitle: "少し休憩しましょう",
            .breakCompleteSubtitle: "集中する準備はできましたか？",
            .dismissOverlay: "クリックまたは任意のキーで続行"
        ],
        .korean: [
            .workPhase: "작업 시간",
            .breakPhase: "휴식 시간",
            .start: "시작",
            .pause: "일시 정지",
            .reset: "초기화",
            .switchToBreak: "휴식",
            .switchToWork: "작업",
            .settings: "설정",
            .hideSettings: "설정 숨기기",
            .quit: "종료",
            .autoStartNext: "다음 세션 자동 시작",
            .workDuration: "작업 시간",
            .breakDuration: "휴식 시간",
            .minutes: "분",
            .language: "언어",
            .systemDefault: "시스템 설정 따르기",
            .workCompleteTitle: "작업 세션 완료!",
            .breakCompleteTitle: "휴식 시간 완료!",
            .workCompleteSubtitle: "잠시 휴식하세요.",
            .breakCompleteSubtitle: "다시 집중할 준비가 되었나요?",
            .dismissOverlay: "클릭하거나 아무 키나 눌러 계속하세요."
        ]
    ]
}
