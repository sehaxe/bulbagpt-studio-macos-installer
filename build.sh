#!/bin/bash
set -e # Останавливаем скрипт при любой ошибке

# --- НАСТРОЙКИ ---
APP_NAME="BulbaGPT"
INSTALL_LOCATION="/Applications/$APP_NAME" # Куда ставится программа на Mac пользователя
BUILD_DIR="build_temp"
ROOT_DIR="$BUILD_DIR/root" # Это "виртуальный корень" для pkgbuild
MAIN_REPO_URL="https://github.com/sehaxe/bulbagpt-studio.git"
IDENTIFIER="com.sehaxe.bulbagpt"
VERSION="1.0"

# --- ПРОВЕРКИ ---
# Проверяем, существуют ли нужные файлы ресурсов перед началом
if [ ! -f "resources/launcher.applescript" ]; then
    echo "❌ Ошибка: Файл resources/launcher.applescript не найден."
    exit 1
fi
if [ ! -f "resources/start.sh" ]; then
    echo "❌ Ошибка: Файл resources/start.sh не найден."
    exit 1
fi

echo "🚀 Начинаем сборку $APP_NAME..."

# 1. Очистка старых файлов
echo "🧹 Очистка..."
rm -rf "$BUILD_DIR"
rm -f "${APP_NAME}_Installer.pkg"
rm -f component.pkg
rm -f distribution.xml

# 2. Подготовка структуры папок
# Создаем папку, имитирующую /Applications внутри сборочной директории
mkdir -p "$ROOT_DIR/Applications"

# 3. Скачивание исходного кода
echo "📥 Клонирование репозитория..."
# Клонируем сразу в целевую папку внутри root
git clone "$MAIN_REPO_URL" "$ROOT_DIR$INSTALL_LOCATION"

# Удаляем служебные файлы git, чтобы они не попали в установщик
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.git"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.github"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.gitignore"

# 4. Компиляция Лаунчера (AppleScript)
echo "🍎 Компиляция AppleScript лаунчера..."
osacompile -o "$ROOT_DIR$INSTALL_LOCATION/BulbaGPT Studio.app" resources/launcher.applescript

# 5. Копирование скрипта запуска
echo "📜 Копирование start.sh..."
cp resources/start.sh "$ROOT_DIR$INSTALL_LOCATION/start.sh"
chmod +x "$ROOT_DIR$INSTALL_LOCATION/start.sh"

# 6. Сборка компонента (PKG)
echo "📦 Сборка component.pkg..."

# Формируем массив аргументов для pkgbuild
PKG_ARGS=(
    --root "$ROOT_DIR"
    --identifier "$IDENTIFIER"
    --version "$VERSION"
    --install-location "/"
)

# Проверяем, есть ли папка scripts. Если нет — не добавляем флаг --scripts
if [ -d "scripts" ] && [ "$(ls -A scripts)" ]; then
    echo "   ℹ️ Найдены скрипты установки (pre/post install)."
    PKG_ARGS+=(--scripts scripts)
else
    echo "   ℹ️ Скрипты установки не найдены, собираем без них."
fi

# Запускаем pkgbuild с аргументами
pkgbuild "${PKG_ARGS[@]}" component.pkg

# 7. Финальная упаковка (Productbuild)
echo "💿 Создание дистрибутива..."
productbuild --synthesize --package component.pkg distribution.xml
productbuild --distribution distribution.xml --package-path . "${APP_NAME}_Installer.pkg"

# 8. Уборка
rm component.pkg
rm distribution.xml
rm -rf "$BUILD_DIR"

echo "✅ ГОТОВО! Установщик создан: ${APP_NAME}_Installer.pkg"