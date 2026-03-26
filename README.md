# SwiftTranslate

[![Build & Release](https://github.com/philippbev/SwiftTranslate/actions/workflows/release.yml/badge.svg)](https://github.com/philippbev/SwiftTranslate/actions/workflows/release.yml)

A native macOS menu bar app for fast, offline translation between English and German. Powered by Apple's on-device Translation framework — no account, no internet, no tracking.

---

## Features

- Instant EN ↔ DE translation from the menu bar
- Fully offline — uses Apple's on-device Translation framework
- Auto-detects input language
- Auto-copies result to clipboard (optional)
- Global hotkey to open/close the app
- Translation history (last 10 entries)
- Dark and light mode support

## Requirements

- macOS 15 Sequoia or later
- Apple Silicon or Intel Mac

## Installation

1. Download `SwiftTranslate.dmg` from the [latest release](https://github.com/philippbev/SwiftTranslate/releases/latest).
2. Open the DMG and drag **SwiftTranslate.app** to your Applications folder.
3. On first launch, right-click → **Open** to bypass Gatekeeper (the app is unsigned).

## Build from Source

```bash
# Clone the repo
git clone https://github.com/philippbev/SwiftTranslate.git
cd SwiftTranslate

# Build (debug)
swift build

# Build (release, universal binary)
swift build -c release --arch arm64 --arch x86_64
```

Requires Xcode 16+ and Swift 5.9+.

## License

MIT — see [LICENSE](LICENSE).
