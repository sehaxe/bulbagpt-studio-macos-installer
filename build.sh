#!/bin/bash
set -e # Останавливаем скрипт при любой ошибке

# --- НАСТРОЙКИ ---
APP_NAME="BulbaGPT"
# Папка, куда ставится софт на Mac пользователя
INSTALL_LOCATION="/Applications/$APP_NAME"
BUILD_DIR="build_temp"
ROOT_DIR="$BUILD_DIR/root"
MAIN_REPO_URL="https://github.com/sehaxe/bulbagpt-studio.git"
IDENTIFIER="com.sehaxe.bulbagpt"
VERSION="1.0"

echo "🚀 Начинаем сборку $APP_NAME..."

# 1. Очистка старых файлов
echo "🧹 Очистка..."
rm -rf "$BUILD_DIR"
rm -f "${APP_NAME}_Installer.pkg"
rm -f component.pkg
rm -f distribution.xml

# 2. Подготовка структуры папок
mkdir -p "$ROOT_DIR/Applications"

# 3. Скачивание исходного кода (в /Applications/BulbaGPT)
echo "📥 Клонирование репозитория..."
git clone "$MAIN_REPO_URL" "$ROOT_DIR$INSTALL_LOCATION"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.git"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.github"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.gitignore"

# 4. Компиляция Лаунчера
echo "🍎 Компиляция AppleScript лаунчера..."
if [ ! -f "resources/launcher.applescript" ]; then
    echo "❌ Ошибка: resources/launcher.applescript не найден!"
    exit 1
fi
osacompile -o "$ROOT_DIR$INSTALL_LOCATION/BulbaGPT Studio.app" resources/launcher.applescript

# 5. Копирование start.sh ВНУТРЬ приложения
# Теперь мы кладем скрипт в Contents/Resources, чтобы AppleScript мог его найти командой path to resource
echo "📜 Копирование start.sh в ресурсы приложения..."
APP_RESOURCES="$ROOT_DIR$INSTALL_LOCATION/BulbaGPT Studio.app/Contents/Resources"
mkdir -p "$APP_RESOURCES"

if [ -f "resources/start.sh" ]; then
    cp resources/start.sh "$APP_RESOURCES/start.sh"
    chmod +x "$APP_RESOURCES/start.sh"
else
    echo "❌ Ошибка: resources/start.sh не найден!"
    exit 1
fi

# 6. Сборка пакета (PKG)
echo "📦 Сборка component.pkg..."

PKG_ARGS=(
    --root "$ROOT_DIR"
    --identifier "$IDENTIFIER"
    --version "$VERSION"
    --install-location "/"
    --ownership recommended
)

# Проверка и подготовка скриптов установки (postinstall)
if [ -d "scripts" ] && [ "$(ls -A scripts)" ]; then
    echo "   🔧 Исправление прав для скриптов установки..."
    chmod -R +x scripts/
    echo "   ℹ️ Добавляем скрипты (postinstall)."
    PKG_ARGS+=(--scripts scripts)
fi

pkgbuild "${PKG_ARGS[@]}" component.pkg

# 7. Финальная упаковка
echo "💿 Создание дистрибутива..."
productbuild --synthesize --package component.pkg distribution.xml
productbuild --distribution distribution.xml --package-path . "${APP_NAME}_Installer.pkg"

# 8. Уборка
rm component.pkg
rm distribution.xml
rm -rf "$BUILD_DIR"

echo "✅ ГОТОВО! Установщик создан: ${APP_NAME}_Installer.pkg"