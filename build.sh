#!/bin/bash
set -e # Остановка при любой ошибке

# --- НАСТРОЙКИ ---
APP_NAME="BulbaGPT"
INSTALL_LOCATION="/Applications/$APP_NAME"
BUILD_DIR="build_temp"
ROOT_DIR="$BUILD_DIR/root"
MAIN_REPO_URL="https://github.com/sehaxe/bulbagpt-studio.git"
IDENTIFIER="com.sehaxe.bulbagpt"
VERSION="1.0"

# Путь к .app внутри временной папки сборки
APP_BUNDLE="$ROOT_DIR$INSTALL_LOCATION/BulbaGPT Studio.app"

echo "🚀 Начинаем сборку $APP_NAME (Full Conda Install)..."

# 1. Очистка
echo "🧹 Очистка..."
rm -rf "$BUILD_DIR"
rm -f "${APP_NAME}_Installer.pkg"
rm -f component.pkg
rm -f distribution.xml

# 2. Подготовка структуры
mkdir -p "$ROOT_DIR/Applications"

# 3. Клонирование репозитория
echo "📥 Клонирование репозитория..."
git clone "$MAIN_REPO_URL" "$ROOT_DIR$INSTALL_LOCATION"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.git"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.github"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.gitignore"

# 4. Компиляция Swift-лаунчера
echo "🐦 Компиляция Native Swift Launcher..."
APP_EXECUTABLE_DIR="$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_EXECUTABLE_DIR"

if [ -f "resources/launcher.swift" ]; then
    swiftc resources/launcher.swift -o "$APP_EXECUTABLE_DIR/BulbaGPT Studio"
else
    echo "❌ Ошибка: Файл resources/launcher.swift не найден!"
    exit 1
fi

# 5. Создание Info.plist
echo "📝 Создание Info.plist..."
mkdir -p "$APP_BUNDLE/Contents"
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BulbaGPT Studio</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$IDENTIFIER</string>
    <key>CFBundleName</key>
    <string>BulbaGPT Studio</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# 6. Копирование ресурсов
echo "📜 Копирование ресурсов..."
APP_RESOURCES="$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_RESOURCES"

# a) Копируем start.sh ВНУТРЬ приложения (для запуска)
if [ -f "resources/start.sh" ]; then
    cp resources/start.sh "$APP_RESOURCES/start.sh"
    chmod +x "$APP_RESOURCES/start.sh"
else
    echo "❌ Ошибка: resources/start.sh не найден!"
    exit 1
fi

# b) Копируем requirements.txt В КОРЕНЬ папки BulbaGPT (для postinstall скрипта)
# Он ляжет в /Applications/BulbaGPT/requirements.txt
if [ -f "resources/requirements.txt" ]; then
    echo "📜 Копирование requirements.txt..."
    cp resources/requirements.txt "$ROOT_DIR$INSTALL_LOCATION/requirements.txt"
else
    echo "⚠️ Внимание: resources/requirements.txt не найден! Установка библиотек будет пропущена."
fi

# 7. Сборка пакета (PKG)
echo "📦 Сборка component.pkg..."

PKG_ARGS=(
    --root "$ROOT_DIR"
    --identifier "$IDENTIFIER"
    --version "$VERSION"
    --install-location "/"
    --ownership recommended
)

if [ -d "scripts" ] && [ "$(ls -A scripts)" ]; then
    echo "   🔧 Настройка скриптов установки..."
    chmod -R +x scripts/
    PKG_ARGS+=(--scripts scripts)
fi

pkgbuild "${PKG_ARGS[@]}" component.pkg

# 8. Финальная упаковка
echo "💿 Создание дистрибутива..."
productbuild --synthesize --package component.pkg distribution.xml
productbuild --distribution distribution.xml --package-path . "${APP_NAME}_Installer.pkg"

# 9. Уборка
rm component.pkg
rm distribution.xml
rm -rf "$BUILD_DIR"

echo "✅ ГОТОВО! Установщик создан: ${APP_NAME}_Installer.pkg"