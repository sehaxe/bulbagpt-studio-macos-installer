# 6. Копирование start.sh и requirements.txt
echo "📜 Копирование ресурсов..."
APP_RESOURCES="$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_RESOURCES"

# start.sh
if [ -f "resources/start.sh" ]; then
    cp resources/start.sh "$APP_RESOURCES/start.sh"
    chmod +x "$APP_RESOURCES/start.sh"
else
    echo "❌ resources/start.sh не найден!"
    exit 1
fi

# requirements.txt -> КОПИРУЕМ В КОРЕНЬ ПРИЛОЖЕНИЯ (для postinstall)
# Postinstall ищет его в /Applications/BulbaGPT/requirements.txt
if [ -f "resources/requirements.txt" ]; then
    echo "📜 Копирование requirements.txt в корень бандла..."
    # $APP_BUNDLE - это .../BulbaGPT Studio.app
    # Но мы ставим его в корень установки, чтобы скрипт его нашел проще
    # ВНИМАНИЕ: pkgbuild ставит содержимое root прямо в install-location.
    # Так что кладем его прямо рядом с .app
    cp resources/requirements.txt "$ROOT_DIR$INSTALL_LOCATION/requirements.txt"
else
    echo "⚠️ ОШИБКА: resources/requirements.txt не найден! Установка зависимостей не сработает."
    exit 1
fi