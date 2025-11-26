# ---------------------------------------------------------
# 4. Компиляция C-лаунчера (Вместо AppleScript)
# ---------------------------------------------------------
echo "🔨 Компиляция Native C Launcher..."

# Путь, куда положим бинарник. 
# ВАЖНО: Бинарники лежат в Contents/MacOS, а не в корне .app
APP_EXECUTABLE_DIR="$ROOT_DIR$INSTALL_LOCATION/BulbaGPT Studio.app/Contents/MacOS"
mkdir -p "$APP_EXECUTABLE_DIR"

if [ -f "resources/launcher.c" ]; then
    # Компилируем C-код в исполняемый файл с именем "applet" (или любым другим)
    # -o указывает выходной файл
    clang -o "$APP_EXECUTABLE_DIR/BulbaGPT Studio" resources/launcher.c
    
    # Делаем его исполняемым
    chmod +x "$APP_EXECUTABLE_DIR/BulbaGPT Studio"
else
    echo "❌ Ошибка: resources/launcher.c не найден!"
    exit 1
fi

# ---------------------------------------------------------
# 4.1 Создание Info.plist (ОБЯЗАТЕЛЬНО для C-лаунчера)
# ---------------------------------------------------------
# AppleScript создавал его сам, а теперь мы должны создать его вручную.
# Без этого файла macOS не поймет, что это приложение.
echo "📝 Создание Info.plist..."
PLIST_PATH="$ROOT_DIR$INSTALL_LOCATION/BulbaGPT Studio.app/Contents/Info.plist"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BulbaGPT Studio</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.sehaxe.bulbagpt</string>
    <key>CFBundleName</key>
    <string>BulbaGPT Studio</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# ---------------------------------------------------------
# 5. Копирование start.sh ВНУТРЬ приложения
# ---------------------------------------------------------
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

# Если есть иконка .icns, скопируй её тоже:
# if [ -f "resources/icon.icns" ]; then
#     cp "resources/icon.icns" "$APP_RESOURCES/AppIcon.icns"
# fi