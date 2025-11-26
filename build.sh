#!/bin/bash
set -e # Останавливать скрипт при ошибке

# --- НАСТРОЙКИ ---
APP_NAME="BulbaGPT"
INSTALL_LOCATION="/Applications/$APP_NAME"
BUILD_DIR="build_temp"
ROOT_DIR="$BUILD_DIR/root"
MAIN_REPO_URL="https://github.com/sehaxe/bulbagpt-studio.git"
IDENTIFIER="com.sehaxe.bulbagpt"
VERSION="1.0"

# Путь к самому приложению внутри папки сборки
APP_BUNDLE="$ROOT_DIR$INSTALL_LOCATION/BulbaGPT Studio.app"

echo "🚀 Начинаем сборку $APP_NAME..."

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
# Удаляем мусор git
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.git"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.github"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.gitignore"

# 4. Компиляция C-лаунчера
echo "🔨 Компиляция Native C Launcher..."
APP_EXECUTABLE_DIR="$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_EXECUTABLE_DIR"

if [ -f "resources/launcher.c" ]; then
    # Компилируем C в бинарник
    clang -o "$APP_EXECUTABLE_DIR/BulbaGPT Studio" resources/launcher.c
    # Делаем исполняемым
    chmod +x "$APP_EXECUTABLE_DIR/BulbaGPT Studio"
else
    echo "❌ Ошибка: Файл resources/launcher.c не найден!"
    exit 1
fi

# 5. Создание Info.plist (Паспорт приложения)
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
</dict>
</plist>
EOF

# 6. Копирование start.sh
echo "📜 Копирование start.sh в Resources..."
APP_RESOURCES="$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_RESOURCES"

if [ -f "resources/start.sh" ]; then
    cp resources/start.sh "$APP_RESOURCES/start.sh"
    chmod +x "$APP_RESOURCES/start.sh"
else
    echo "❌ Ошибка: resources/start.sh не найден!"
    exit 1
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
    echo "   🔧 Исправление прав скриптов..."
    chmod -R +x scripts/
    echo "   ℹ️ Добавляем скрипты установки (postinstall)."
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