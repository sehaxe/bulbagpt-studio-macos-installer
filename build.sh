#!/bin/bash
set -e

# --- CONFIGURATION ---
APP_NAME="BulbaGPT Studio"
REPO_URL="https://github.com/sehaxe/bulbagpt-studio.git"
IDENTIFIER="com.sehaxe.bulbagpt"
VERSION="1.0"

# --- PATHS ---
BUILD_DIR="build_temp"
SOURCE_DIR="$BUILD_DIR/source"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RES_DIR="$CONTENTS_DIR/Resources"

echo "🚀 Starting build for $APP_NAME..."

# 1. CLEANUP
rm -rf "$BUILD_DIR"
rm -f "${APP_NAME}_Installer.pkg"
rm -f component.pkg
rm -f distribution.xml

# 2. CLONE REPOSITORY
echo "📥 Cloning source code..."
mkdir -p "$BUILD_DIR"
git clone "$REPO_URL" "$SOURCE_DIR"

# 3. PREPARE APP BUNDLE
mkdir -p "$MACOS_DIR"
mkdir -p "$RES_DIR"

# 4. COPY SOURCE CODE
echo "📂 Copying C source code..."
# IMPORTANT: Assumes your C code and Makefile are in 'backend'
if [ -d "$SOURCE_DIR/backend" ]; then
    cp -r "$SOURCE_DIR/backend" "$RES_DIR/src"
else
    echo "❌ Error: 'backend' folder not found in repo."
    exit 1
fi

# Copy Python requirements
if [ -f "$SOURCE_DIR/uv.lock" ]; then cp "$SOURCE_DIR/uv.lock" "$RES_DIR/src/"; fi
if [ -f "$SOURCE_DIR/pyproject.toml" ]; then cp "$SOURCE_DIR/pyproject.toml" "$RES_DIR/src/"; fi
if [ -f "$SOURCE_DIR/requirements.txt" ]; then cp "$SOURCE_DIR/requirements.txt" "$RES_DIR/src/"; fi

# 5. DOWNLOAD STANDALONE UV
echo "⬇️  Downloading 'uv'..."
mkdir -p "$RES_DIR/tools"
# Download x86_64 binary (Mac Rosetta runs it fine, ensures compatibility)
curl -L -o "$RES_DIR/tools/uv.tar.gz" "https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-apple-darwin.tar.gz"
tar -xzf "$RES_DIR/tools/uv.tar.gz" -C "$RES_DIR/tools"
mv "$RES_DIR/tools/uv-x86_64-apple-darwin/uv" "$RES_DIR/tools/uv"
rm -rf "$RES_DIR/tools/uv.tar.gz" "$RES_DIR/tools/uv-x86_64-apple-darwin"
chmod +x "$RES_DIR/tools/uv"

# 6. CREATE SHIM SCRIPT
# This runs when the user double-clicks the app
cat > "$MACOS_DIR/$APP_NAME" <<EOF
#!/bin/bash
DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
# Binary is located in Resources/bin/bulba_studio (after postinstall compiles it)
EXEC_PATH="\$DIR/../Resources/bin/bulba_studio"
if [ -f "\$EXEC_PATH" ]; then
    exec "\$EXEC_PATH"
else
    osascript -e 'display alert "Build Error" message "The application binary is missing. Please reinstall or check permissions."'
fi
EOF
chmod +x "$MACOS_DIR/$APP_NAME"

# 7. ICON & PLIST
if [ -f "$SOURCE_DIR/resources/AppIcon.icns" ]; then
    cp "$SOURCE_DIR/resources/AppIcon.icns" "$RES_DIR/AppIcon.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$IDENTIFIER</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 8. BUILD INSTALLER
echo "📦 Packaging..."
PKG_ARGS=(
    --root "$APP_BUNDLE"
    --identifier "$IDENTIFIER"
    --version "$VERSION"
    --install-location "/Applications/$APP_NAME.app"
)
if [ -d "scripts" ]; then
    chmod -R +x scripts/
    PKG_ARGS+=(--scripts scripts)
else
    echo "❌ Error: 'scripts/postinstall' missing."
    exit 1
fi

pkgbuild "${PKG_ARGS[@]}" component.pkg

# 9. FINALIZE
productbuild --synthesize --package component.pkg distribution.xml
# (Optional: Inject XML UI here if you have assets)
productbuild --distribution distribution.xml --package-path . "${APP_NAME}_Installer.pkg"

rm component.pkg distribution.xml
rm -rf "$BUILD_DIR"
echo "✅ DONE! Installer: ${APP_NAME}_Installer.pkg"