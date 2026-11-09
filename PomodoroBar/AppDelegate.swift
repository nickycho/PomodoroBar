import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let timerManager = TimerManager()
    private var fullScreenController: FullScreenWindowController?
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    private static let monoDigitAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    ]
    private var lastTitleString: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
        timerManager.onPhaseComplete = { [weak self] in
            self?.handlePhaseComplete()
        }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self

        // 只訂閱會影響顯示的三個 publisher，不需要 CombineLatest3（更輕量），
        // 且 publisher 已在 main thread 發佈，省去 receive(on:) 的 hop。
        timerManager.$remainingSeconds
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)
        timerManager.$state
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)
        timerManager.$phase
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)

        updateTitle()
    }

    private func updateTitle() {
        let icon = timerManager.phase == .work ? "🍅" : "☕️"
        let time = timerManager.state == .idle ? "" : timerManager.timeString
        let combined = time.isEmpty ? "\(icon) " : "\(icon) \(time)"

        // 字串沒變就不更新 status bar，避免 AppKit 重排版/重繪
        if combined == lastTitleString { return }
        lastTitleString = combined

        let attributed = NSMutableAttributedString(string: "\(icon) ")
        if !time.isEmpty {
            attributed.append(NSAttributedString(string: time, attributes: Self.monoDigitAttributes))
        }
        statusItem.button?.attributedTitle = attributed
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 370)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(timerManager: timerManager)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopover()
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Full Screen

    private func handlePhaseComplete() {
        let soundName: NSSound.Name = timerManager.phase == .work ? "Glass" : "Ping"
        NSSound(named: soundName)?.play()
        showFullScreen()
    }

    private func showFullScreen() {
        let completedPhase = timerManager.phase
        fullScreenController = FullScreenWindowController(
            completedPhase: completedPhase,
            onDismiss: { [weak self] in
                guard let self else { return }
                let next: TimerPhase = completedPhase == .work ? .shortBreak : .work
                self.timerManager.switchPhase(to: next)
                self.fullScreenController = nil
                if self.timerManager.autoStart {
                    self.timerManager.start()
                }
            }
        )
        fullScreenController?.show()
    }
}
