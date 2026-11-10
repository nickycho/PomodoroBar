# PomodoroBar

A lightweight native Pomodoro timer that lives in the macOS menu bar.

## Features

- See a tomato or coffee icon in the menu bar, with a countdown while a timer is running.
- Switch between work and short-break sessions, with 25-minute and 5-minute defaults.
- Configure work sessions from 1 to 60 minutes and breaks from 1 to 30 minutes.
- Start, pause, reset, or switch the current phase from the menu bar popover.
- Get a full-screen completion overlay on each display, with a distinct sound for work and break sessions.
- Dismiss the completion overlay with any click or key press.
- Optionally start the next phase automatically after dismissing the overlay.
- Keep timer preferences locally in macOS `UserDefaults`.
- Use the interface in English, Traditional Chinese, Japanese, or Korean, with system language detection and a persistent language preference.

## Requirements

- macOS 13 or later
- Swift 5.9 or later

## Build and run

Build and launch the app with Swift Package Manager:

```sh
swift run
```

To create an optimized build:

```sh
swift build -c release
.build/release/PomodoroBar
```

Click the menu bar item to open the timer and settings. Use **Quit** in the popover to exit the app.

## Notes

- The app has no third-party package dependencies.
- System language is used by default, with English as the fallback for unsupported languages.
- Select a language from the settings panel to override the system language.
- Starting the app automatically at login is not currently supported.
