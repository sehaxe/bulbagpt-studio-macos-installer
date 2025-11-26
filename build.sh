#!/bin/bash
set -e

# --- НАСТРОЙКИ ---
APP_NAME="BulbaGPT"
INSTALL_LOCATION="/Applications/$APP_NAME"
BUILD_DIR="build_temp"
ROOT_DIR="$BUILD_DIR/root"
MAIN_REPO_URL="https://github.com/sehaxe/bulbagpt-studio.git"
IDENTIFIER="com.sehaxe.bulbagpt"
VERSION="1.0"

APP_BUNDLE="$ROOT_DIR$INSTALL_LOCATION/BulbaGPT Studio.app"

echo "🚀 Начинаем сборку $APP_NAME (Icon Edition)..."

# 1. Очистка
echo "🧹 Очистка..."
rm -rf "$BUILD_DIR"
rm -f "${APP_NAME}_Installer.pkg"
rm -f component.pkg
rm -f distribution.xml

# 2. Подготовка
mkdir -p "$ROOT_DIR/Applications"

# 3. Клонирование
echo "📥 Клонирование..."
git clone "$MAIN_REPO_URL" "$ROOT_DIR$INSTALL_LOCATION"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.git"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.github"
rm -rf "$ROOT_DIR$INSTALL_LOCATION/.gitignore"

# 4. Компиляция Swift-лаунчера
echo "🐦 Компиляция Launcher..."
APP_EXECUTABLE_DIR="$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_EXECUTABLE_DIR"

if [ -f "resources/launcher.swift" ]; then
    swiftc resources/launcher.swift -o "$APP_EXECUTABLE_DIR/BulbaGPT Studio"
else
    echo "❌ Ошибка: resources/launcher.swift не найден!"
    exit 1
fi

# 5. Создание Info.plist (С ИКОНКОЙ)
echo "📝 Создание Info.plist..."
mkdir -p "$APP_BUNDLE/Contents"
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BulbaGPT Studio</string>
    
    <!-- ИМЯ ФАЙЛА ИКОНКИ (без расширения) -->
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
    
    <!-- false = ПОКАЗЫВАТЬ В ДОКЕ (Стандартное приложение) -->
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# 6. Копирование ресурсов
echo "📜 Копирование ресурсов..."
APP_RESOURCES="$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_RESOURCES"

# a) Копируем start.sh
if [ -f "resources/start.sh" ]; then
    cp resources/start.sh "$APP_RESOURCES/start.sh"
    chmod +x "$APP_RESOURCES/start.sh"
else
    echo "❌ resources/start.sh не найден!"
    exit 1
fi

# b) Копируем requirements.txt
if [ -f "resources/requirements.txt" ]; then
    cp resources/requirements.txt "$ROOT_DIR$INSTALL_LOCATION/requirements.txt"
fi

# c) КОПИРУЕМ ИКОНКУ (НОВОЕ)
if [ -f "resources/AppIcon.icns" ]; then
    echo "🎨 Установка иконки..."
    cp "resources/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
else
    echo "⚠️ Иконка AppIcon.icns не найдена в папке resources! Будет стандартная иконка."
fi

# 7. Сборка пакета
echo "📦 Сборка component.pkg..."
PKG_ARGS=(
    --root "$ROOT_DIR"
    --identifier "$IDENTIFIER"
    --version "$VERSION"
    --install-location "/"
    --ownership recommended
)
if [ -d "scripts" ]; then
    chmod -R +x scripts/
    PKG_ARGS+=(--scripts scripts)
fi
pkgbuild "${PKG_ARGS[@]}" component.pkg

# 8. Финальная упаковка (Дизайн установщика)
echo "💿 Создание дистрибутива..."

# Создаем XML
productbuild --synthesize --package component.pkg distribution.xml

# Добавляем дизайн (фон, приветствие) в XML
python3 -c "
import xml.etree.ElementTree as ET
try:
    tree = ET.parse('distribution.xml')
    root = tree.getroot()
    
    title = ET.Element('title')
    title.text = '$APP_NAME Studio'
    root.insert(0, title)
    
    # Если есть файлы дизайна, добавляем их
    import os
    if os.path.exists('installer_assets/background.png'):
        bg = ET.Element('background')
        bg.set('file', 'background.png')
        bg.set('alignment', 'bottomleft')
        bg.set('scaling', 'proportional')
        root.append(bg)
        
    if os.path.exists('installer_assets/welcome.html'):
        wel = ET.Element('welcome')
        wel.set('file', 'welcome.html')
        root.append(wel)
        
    if os.path.exists('installer_assets/conclusion.html'):
        conc = ET.Element('conclusion')
        conc.set('file', 'conclusion.html')
        root.append(conc)
        
    tree.write('distribution.xml', encoding='utf-8', xml_declaration=True)
except Exception as e:
    print('Ошибка при настройке XML:', e)
"

# Собираем
if [ -d "installer_assets" ]; then
    productbuild --distribution distribution.xml \
                 --resources installer_assets \
                 --package-path . \
                 "${APP_NAME}_Installer.pkg"
else
    productbuild --distribution distribution.xml \
                 --package-path . \
                 "${APP_NAME}_Installer.pkg"
fi

# 9. Уборка
rm component.pkg
rm distribution.xml
rm -rf "$BUILD_DIR"

echo "✅ ГОТОВО! Установщик: ${APP_NAME}_Installer.pkg"