#!/usr/bin/env bash
set -euo pipefail

APP=SwiftTranslate.app
BUILD=.build/apple/Products/Release

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

# Main binary
cp "$BUILD/SwiftTranslate" "$APP/Contents/MacOS/SwiftTranslate"

# App resource bundle — must be copied as a whole so Bundle.module can find it
if [ -d "$BUILD/SwiftTranslate_SwiftTranslate.bundle" ]; then
  cp -R "$BUILD/SwiftTranslate_SwiftTranslate.bundle" \
    "$APP/Contents/Resources/"
fi

# App icon — must sit directly in Contents/Resources/ (not inside the sub-bundle)
# so macOS Finder/Dock picks it up via CFBundleIconFile
if [ -f "$BUILD/SwiftTranslate_SwiftTranslate.bundle/Contents/Resources/AppIcon.icns" ]; then
  cp "$BUILD/SwiftTranslate_SwiftTranslate.bundle/Contents/Resources/AppIcon.icns" \
    "$APP/Contents/Resources/AppIcon.icns"
fi

# KeyboardShortcuts bundle (required dependency)
if [ -d "$BUILD/KeyboardShortcuts_KeyboardShortcuts.bundle" ]; then
  cp -R "$BUILD/KeyboardShortcuts_KeyboardShortcuts.bundle" \
    "$APP/Contents/Resources/"
fi

# Info.plist
SHORT_SHA=$(git rev-parse --short HEAD)
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>SwiftTranslate</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>com.philippbev.SwiftTranslate</string>
  <key>CFBundleName</key><string>SwiftTranslate</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>${SHORT_SHA}</string>
  <key>LSMinimumSystemVersion</key><string>15.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
EOF

echo "Bundle created:"
find "$APP" -maxdepth 3
