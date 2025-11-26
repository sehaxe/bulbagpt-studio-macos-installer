#!/bin/bash

# Настройки
APP_NAME="BulbaGPT"
INSTALL_DIR="/Applications/$APP_NAME"
BUILD_DIR="build_temp"
ROOT_DIR="$BUILD_DIR/root"
MAIN_REPO_URL="https://github.com/sehaxe/bulbagpt-studio.git" # <-- ТВОЙ ОСНОВНОЙ РЕПО

echo "🚀 Starting Build Process for $APP_NAME..."

# 1. Очистка
rm -rf "$BUILD_DIR"
rm -f "${APP_NAME}_Installer.pkg"
mkdir -p "$ROOT_DIR$INSTALL_DIR"

# 2. Скачивание исходного кода
echo "📥 Cloning source code from GitHub..."
git clone "$MAIN_REPO_URL" "$ROOT_DIR$INSTALL_DIR"
# Удаляем лишнее из клона (.git, venv если есть)
rm -rf "$ROOT_DIR$INSTALL_DIR/.git"
rm -rf "$ROOT_DIR$INSTALL_DIR/.github"
rm -rf "$ROOT_DIR$INSTALL_DIR/.gitignore"

# 3. Компиляция Лаунчера
echo "🍎 Compiling AppleScript Launcher..."
osacompile -o "$ROOT_DIR$INSTALL_DIR/BulbaGPT Studio.app" resources/launcher.applescript

# Если у тебя есть иконка, раскомментируй строку ниже:
# cp resources/icon.icns "$ROOT_DIR$INSTALL_DIR/BulbaGPT Studio.app/Contents/Resources/applet.icns"

# 4. Копирование скрипта запуска
echo "📜 Copying start scripts..."
cp resources/start.sh "$ROOT_DIR$INSTALL_DIR/start.sh"
chmod +x "$ROOT_DIR$INSTALL_DIR/start.sh"

# 5. Сборка пакета (PKG)
echo "📦 Building .pkg package..."
pkgbuild --root "$ROOT_DIR" \
         --scripts scripts \
         --identifier com.sehaxe.bulbagpt \
         --version 1.0 \
         --install-location "/" \
         component.pkg

# 6. Финальная упаковка (Productbuild)
echo "💿 Creating distribution..."
productbuild --synthesize --package component.pkg distribution.xml
productbuild --distribution distribution.xml --package-path . "${APP_NAME}_Installer.pkg"

# 7. Уборка
rm component.pkg
rm distribution.xml
# rm -rf "$BUILD_DIR" # Можно оставить для отладки

echo "✅ DONE! Installer created: ${APP_NAME}_Installer.pkg"
