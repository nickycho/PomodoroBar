import Foundation

enum TimerPhase {
    case work
    case shortBreak
}

enum TimerState {
    case idle
    case running
    case paused
}

class TimerManager: ObservableObject {
    @Published var phase: TimerPhase = .work
    @Published var state: TimerState = .idle
    @Published var remainingSeconds: Int = 0

    var autoStart: Bool {
        get { UserDefaults.standard.bool(forKey: "autoStart") }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoStart")
            objectWillChange.send()
        }
    }

    var workDuration: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "workDuration")
            return val > 0 ? val : 25
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "workDuration")
            objectWillChange.send()
            if state == .idle && phase == .work {
                remainingSeconds = newValue * 60
            }
        }
    }

    var breakDuration: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "breakDuration")
            return val > 0 ? val : 5
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "breakDuration")
            objectWillChange.send()
            if state == .idle && phase == .shortBreak {
                remainingSeconds = newValue * 60
            }
        }
    }

    var onPhaseComplete: (() -> Void)?
    private var endDate: Date?
    private var dispatchTimer: DispatchSourceTimer?

    init() {
        let saved = UserDefaults.standard.integer(forKey: "workDuration")
        remainingSeconds = (saved > 0 ? saved : 25) * 60
    }

    var totalSeconds: Int {
        phase == .work ? workDuration * 60 : breakDuration * 60
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func start() {
        guard state != .running else { return }
        state = .running
        endDate = Date().addingTimeInterval(Double(remainingSeconds))
        scheduleTimer()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        cancelTimer()
    }

    func reset() {
        cancelTimer()
        state = .idle
        endDate = nil
        remainingSeconds = totalSeconds
    }

    func switchPhase(to newPhase: TimerPhase) {
        cancelTimer()
        phase = newPhase
        state = .idle
        endDate = nil
        remainingSeconds = totalSeconds
    }

    private func scheduleTimer() {
        let t = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        // leeway 讓 OS 可以 coalesce timer events，降低不必要的 CPU wakeup
        t.schedule(deadline: .now() + 1, repeating: 1, leeway: .milliseconds(100))
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        dispatchTimer = t
    }

    private func cancelTimer() {
        dispatchTimer?.cancel()
        dispatchTimer = nil
    }

    private func tick() {
        guard let endDate else { return }
        let remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if remaining > 0 {
                // 同一秒不重複 publish，避免觸發 SwiftUI / Combine 整條 pipeline
                if self.remainingSeconds != remaining {
                    self.remainingSeconds = remaining
                }
            } else {
                self.cancelTimer()
                self.remainingSeconds = 0
                self.state = .idle
                self.onPhaseComplete?()
            }
        }
    }
}
