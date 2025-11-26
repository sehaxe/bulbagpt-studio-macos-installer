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

echo "🚀 Начинаем сборку $APP_NAME (Design Edition)..."

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
echo "🐦 Компиляция Swift Launcher..."
APP_EXECUTABLE_DIR="$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_EXECUTABLE_DIR"
if [ -f "resources/launcher.swift" ]; then
    swiftc resources/launcher.swift -o "$APP_EXECUTABLE_DIR/BulbaGPT Studio"
else
    echo "❌ Ошибка: resources/launcher.swift не найден"
    exit 1
fi

# 5. Info.plist
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

# 6. Ресурсы
echo "📜 Копирование ресурсов..."
APP_RESOURCES="$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_RESOURCES"
cp resources/start.sh "$APP_RESOURCES/start.sh"
chmod +x "$APP_RESOURCES/start.sh"

if [ -f "resources/requirements.txt" ]; then
    cp resources/requirements.txt "$ROOT_DIR$INSTALL_LOCATION/requirements.txt"
fi

# 7. Сборка компонента
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

# ------------------------------------------------------------------
# 8. СОЗДАНИЕ КРАСИВОГО ДИСТРИБУТИВА (ГЛАВНОЕ ИЗМЕНЕНИЕ)
# ------------------------------------------------------------------
echo "🎨 Настройка дизайна установщика..."

# Генерируем базовый XML
productbuild --synthesize --package component.pkg distribution.xml

# Внедряем настройки дизайна в XML с помощью python (так проще всего вставить текст в XML)
# Мы добавляем теги <title>, <background>, <welcome>, <license>, <conclusion>
python3 -c "
import xml.etree.ElementTree as ET

tree = ET.parse('distribution.xml')
root = tree.getroot()

# Устанавливаем заголовок окна
title = ET.Element('title')
title.text = '$APP_NAME Studio'
root.insert(0, title)

# Добавляем фон
bg = ET.Element('background')
bg.set('file', 'background.jpg')
bg.set('alignment', 'bottomleft') # или 'topleft', 'center'
bg.set('scaling', 'proportional')
root.append(bg)

# Добавляем HTML страницы
welcome = ET.Element('welcome')
welcome.set('file', 'welcome.html')
root.append(welcome)

license = ET.Element('license')
license.set('file', 'license.html')
root.append(license)

conclusion = ET.Element('conclusion')
conclusion.set('file', 'conclusion.html')
root.append(conclusion)

tree.write('distribution.xml', encoding='utf-8', xml_declaration=True)
"

echo "💿 Финальная упаковка с ресурсами..."

# --resources указывает папку, где лежат картинки и html
productbuild --distribution distribution.xml \
             --resources installer_assets \
             --package-path . \
             "${APP_NAME}_Installer.pkg"

# 9. Уборка
rm component.pkg
rm distribution.xml
rm -rf "$BUILD_DIR"

echo "✅ ГОТОВО! Красивый установщик: ${APP_NAME}_Installer.pkg"