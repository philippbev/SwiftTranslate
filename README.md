# SwiftTranslate

A lightweight macOS menu bar app for fast, offline translation — powered by Apple's on-device Translation framework. No account, no internet, no tracking.

<!-- Screenshot placeholder -->
<!-- ![SwiftTranslate](screenshot.png) -->

---

## Features

- **Offline & Private** — Uses Apple's native Translation framework. Nothing leaves your Mac.
- **Menu Bar Integration** — Always one click away, without cluttering your Dock.
- **Global Hotkey** — Open the translator from anywhere with `⌥⇧T` (customizable).
- **Auto Language Detection** — Detects EN, DE, FR, ES, IT automatically as you type.
- **Auto-Translate** — Translate on paste or while typing (configurable).
- **Auto-Copy** — Translation is copied to your clipboard instantly.
- **Translation History** — Last 10 translations, synced via iCloud across your Macs.
- **Language Lock** — Pin the source language to prevent auto-detection.
- **Swap Languages** — Flip source and target with one click.

---

## Requirements

| | |
|---|---|
| **macOS** | 15.0 Sequoia or later |
| **Architecture** | Apple Silicon & Intel |
| **Disk space** | ~300–600 MB (language packs, downloaded on first launch) |

---

## Installation

### Download
Grab the latest release from the [Releases](../../releases) page, unzip, and drag **SwiftTranslate.app** to your `/Applications` folder.

### Build from source
```bash
git clone https://github.com/philippbev/SwiftTranslate.git
cd SwiftTranslate
swift build -c release
```

Or open the project in Xcode and run the `SwiftTranslate` scheme.

---

## First Launch

On first launch, SwiftTranslate walks you through a short onboarding:

1. **Welcome** — Overview of features.
2. **Download language packs** — Downloads EN↔DE translation models (~300–600 MB total). Required once; works offline afterwards.
3. **Ready** — You're set. Press `⌥⇧T` from anywhere.

---

## Usage

| Action | How |
|---|---|
| Open translator | Click the `🔤` menu bar icon — or press `⌥⇧T` |
| Translate | Type text, then press `⌘↵` or click **Translate** |
| Swap languages | Click the `⇄` button between the language names |
| Lock source language | Click the `🔒` icon next to the source language |
| View history | Click the `🕐` icon in the bottom bar |
| Open settings | Click the `⚙︎` icon in the bottom bar |
| Quit | Click the `⏻` icon in the bottom bar |

---

## Supported Languages

| Language | Code |
|---|---|
| English | `en` 🇬🇧 |
| German | `de` 🇩🇪 |
| French | `fr` 🇫🇷 |
| Spanish | `es` 🇪🇸 |
| Italian | `it` 🇮🇹 |

Language detection and translation are powered by Apple's [`Translation`](https://developer.apple.com/documentation/translation) and [`NaturalLanguage`](https://developer.apple.com/documentation/naturallanguage) frameworks.

---

## Settings

Open **Settings** via the `⚙︎` icon or `⌘,`:

- **Keyboard Shortcut** — Customize or reset the global hotkey.
- **Source / Target Language** — Set default language pair.
- **Auto-translate on paste** — Translate automatically when text is pasted.
- **Auto-translate while typing** — Translate after 800ms of inactivity.
- **Copy translation to clipboard** — Auto-copy every result.
- **Clear History** — Remove all saved translations.

---

## Architecture

```
SwiftTranslate/
├── App/                    # App entry point, AppDelegate, AppState, Localization
├── Core/
│   ├── Models.swift        # SupportedLanguage, HistoryEntry
│   ├── Persistence/        # HistoryStore (local + iCloud), OnboardingStore
│   └── Services/           # HotkeyManager, LanguageDetector
└── Features/
    ├── Translator/         # MenuBarView, MultilineTextField
    ├── History/            # HistoryView
    ├── Settings/           # SettingsView
    └── Onboarding/         # OnboardingView (3-step flow)
```

**State management:** Centralized `AppState` using Swift's `@Observable` macro.
**Translation:** Apple `TranslationSession` via the `.translationTask()` SwiftUI modifier.
**Persistence:** `UserDefaults` for settings, `NSUbiquitousKeyValueStore` for iCloud history sync.

---

## Dependencies

| Package | Purpose |
|---|---|
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | Global hotkey registration and recorder UI |

---

## Localization

SwiftTranslate ships with full UI localization in **English** and **German**. All strings live in `Resources/{en,de}.lproj/Localizable.strings`.

---

## Privacy

SwiftTranslate does not collect, transmit, or store any data outside your device and your personal iCloud account. Translation is performed entirely on-device using Apple's Translation framework.

---

## License

MIT — see [LICENSE](LICENSE).
