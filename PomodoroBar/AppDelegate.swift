import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let timerManager = TimerManager()
    private let languageManager = LanguageManager()
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
        let time = timerManager.state == .idle ? "" : timerManager.timeString

        // Skip redundant AppKit updates to avoid unnecessary status bar redraws.
        if time == lastTitleString { return }
        lastTitleString = time

        statusItem.button?.image = Self.tomatoTimerMenuBarImage
        statusItem.button?.imagePosition = .imageLeading

        let attributed = NSMutableAttributedString(string: "")
        if !time.isEmpty {
            attributed.append(NSAttributedString(string: time, attributes: Self.monoDigitAttributes))
        }
        statusItem.button?.attributedTitle = attributed
    }


    private static let tomatoTimerMenuBarImage: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        NSColor.white.setStroke()

        let body = NSBezierPath()
        body.move(to: NSPoint(x: 9, y: 13.5))
        body.curve(to: NSPoint(x: 15.5, y: 11.5),
                   controlPoint1: NSPoint(x: 11.5, y: 14.7),
                   controlPoint2: NSPoint(x: 14.6, y: 13.5))
        body.curve(to: NSPoint(x: 16.2, y: 7),
                   controlPoint1: NSPoint(x: 16.5, y: 10.5),
                   controlPoint2: NSPoint(x: 16.5, y: 8.5))
        body.curve(to: NSPoint(x: 12.2, y: 2.8),
                   controlPoint1: NSPoint(x: 15.5, y: 4.8),
                   controlPoint2: NSPoint(x: 14.1, y: 3.2))
        body.curve(to: NSPoint(x: 9, y: 3.8),
                   controlPoint1: NSPoint(x: 11.1, y: 2.4),
                   controlPoint2: NSPoint(x: 10, y: 3.5))
        body.curve(to: NSPoint(x: 5.8, y: 2.8),
                   controlPoint1: NSPoint(x: 8, y: 3.5),
                   controlPoint2: NSPoint(x: 6.9, y: 2.4))
        body.curve(to: NSPoint(x: 1.8, y: 7),
                   controlPoint1: NSPoint(x: 3.9, y: 3.2),
                   controlPoint2: NSPoint(x: 2.4, y: 4.8))
        body.curve(to: NSPoint(x: 2.5, y: 11.5),
                   controlPoint1: NSPoint(x: 1.4, y: 8.5),
                   controlPoint2: NSPoint(x: 1.7, y: 10.5))
        body.curve(to: NSPoint(x: 9, y: 13.5),
                   controlPoint1: NSPoint(x: 4.4, y: 13.5),
                   controlPoint2: NSPoint(x: 6.7, y: 14.5))
        body.close()
        body.lineWidth = 1.2
        body.lineCapStyle = .round
        body.lineJoinStyle = .round
        body.stroke()

        let crown = NSBezierPath()
        crown.move(to: NSPoint(x: 9, y: 13.3))
        crown.line(to: NSPoint(x: 6.2, y: 16.1))
        crown.line(to: NSPoint(x: 8.7, y: 15.3))
        crown.line(to: NSPoint(x: 9.2, y: 17))
        crown.line(to: NSPoint(x: 10, y: 15.3))
        crown.line(to: NSPoint(x: 12.2, y: 16))
        crown.line(to: NSPoint(x: 10.8, y: 13.3))
        crown.lineWidth = 1.2
        crown.lineCapStyle = .round
        crown.lineJoinStyle = .round
        crown.stroke()

        let dialArc = NSBezierPath()
        dialArc.move(to: NSPoint(x: 2.7, y: 6.8))
        dialArc.curve(to: NSPoint(x: 15.3, y: 6.8),
                      controlPoint1: NSPoint(x: 6, y: 4.8),
                      controlPoint2: NSPoint(x: 12, y: 4.8))
        dialArc.lineWidth = 1
        dialArc.lineCapStyle = .round
        dialArc.stroke()

        let ticks = NSBezierPath()
        let tickPositions: [(CGFloat, CGFloat)] = [
            (4.2, 7.1), (6.3, 7.8), (9, 8.1),
            (11.7, 7.8), (13.8, 7.1)
        ]
        for (x, y) in tickPositions {
            ticks.move(to: NSPoint(x: x, y: 6.8))
            ticks.line(to: NSPoint(x: x, y: y))
        }
        ticks.lineWidth = 1
        ticks.lineCapStyle = .round
        ticks.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }()

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 370)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                timerManager: timerManager,
                languageManager: languageManager,
                onSettingsVisibilityChange: { [weak self] isVisible in
                    guard let self else { return }
                    self.popover.contentSize = NSSize(width: 280, height: isVisible ? 520 : 370)
                }
            )
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
            languageManager: languageManager,
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
