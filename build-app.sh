#!/bin/zsh
set -e

echo "Building unelaborate..."
swift build -c release

echo "Creating app bundle..."
APP_NAME="unelaborate"
APP_BUNDLE="$APP_NAME.app"
BUILD_DIR=".build/release"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>unelaborate</string>
    <key>CFBundleIdentifier</key>
    <string>app.unelaborate.launcher</string>
    <key>CFBundleName</key>
    <string>unelaborate</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

echo "Done. Launch with: open $APP_BUNDLE"
