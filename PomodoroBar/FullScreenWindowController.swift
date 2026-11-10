import AppKit
import SwiftUI

class FullScreenWindowController {
    private var windows: [NSWindow] = []
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isDismissing = false
    private let onDismiss: () -> Void
    private let languageManager: LanguageManager

    init(completedPhase: TimerPhase, languageManager: LanguageManager, onDismiss: @escaping () -> Void) {
        self.languageManager = languageManager
        self.onDismiss = onDismiss

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            window.isOpaque = false
            window.backgroundColor = .clear
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.contentView = NSHostingView(
                rootView: FullScreenOverlayView(completedPhase: completedPhase, languageManager: languageManager)
            )
            windows.append(window)
        }
    }

    func show() {
        windows.forEach { $0.makeKeyAndOrderFront(nil) }
        NSApp.activate(ignoringOtherApps: true)
        addEventMonitors()
    }

    private func addEventMonitors() {
        let mask: NSEvent.EventTypeMask = [.keyDown, .leftMouseDown, .rightMouseDown]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            self?.dismiss()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.dismiss()
            return event
        }
    }

    private func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true

        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
        globalMonitor = nil
        localMonitor = nil

        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        onDismiss()
    }
}
