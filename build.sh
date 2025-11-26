#!/bin/bash
set -e # Останавливаем скрипт при ошибке

# --- НАСТРОЙКИ ---
APP_NAME="BulbaGPT"
INSTALL_LOCATION="/Applications/$APP_NAME"
BUILD_DIR="build_temp"
ROOT_DIR="$BUILD_DIR/root"
MAIN_REPO_URL="https://github.com/sehaxe/bulbagpt-studio.git"
IDENTIFIER="com.sehaxe.bulbagpt"
VERSION="1.0"

echo "🚀 Начинаем сборку $APP_NAME..."

# 1. Очистка
rm -rf "$BUILD_DIR"
rm -f "${APP_NAME}_Installer.pkg"
rm -f component.pkg
rm -f distribution.xml

# 2. Подготовка
mkdir -p "$ROOT_DIR/Applications"

# 3. Клонирование
echo "📥 Клонирование репозитория..."
git clone "$MAIN_REPO_URL" "$ROOT_DIR$INSTALL_LOCATION"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.git"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.github"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.gitignore"

# 4. Лаунчер
echo "🍎 Компиляция лаунчера..."
if [ -f "resources/launcher.applescript" ]; then
    osacompile -o "$ROOT_DIR$INSTALL_LOCATION/BulbaGPT Studio.app" resources/launcher.applescript
else
    echo "⚠️ Внимание: resources/launcher.applescript не найден!"
fi

# 5. Скрипт запуска
echo "📜 Копирование start.sh..."
if [ -f "resources/start.sh" ]; then
    cp resources/start.sh "$ROOT_DIR$INSTALL_LOCATION/start.sh"
    chmod +x "$ROOT_DIR$INSTALL_LOCATION/start.sh"
fi

# 6. Сборка пакета
echo "📦 Сборка component.pkg..."

PKG_ARGS=(
    --root "$ROOT_DIR"
    --identifier "$IDENTIFIER"
    --version "$VERSION"
    --install-location "/"
    --ownership recommended
)

if [ -d "scripts" ] && [ "$(ls -A scripts)" ]; then
    echo "   🔧 Делаем скрипты исполняемыми (Fix permissions 420)..."
    # ВОТ ЭТО ИСПРАВЛЯЕТ ТВОЮ ОШИБКУ:
    chmod -R +x scripts/
    
    echo "   ℹ️ Добавляем скрипты установки."
    PKG_ARGS+=(--scripts scripts)
fi

pkgbuild "${PKG_ARGS[@]}" component.pkg

# 7. Дистрибутив
echo "💿 Создание дистрибутива..."
productbuild --synthesize --package component.pkg distribution.xml
productbuild --distribution distribution.xml --package-path . "${APP_NAME}_Installer.pkg"

# 8. Уборка
rm component.pkg
rm distribution.xml
rm -rf "$BUILD_DIR"

echo "✅ Установщик готов: ${APP_NAME}_Installer.pkg"