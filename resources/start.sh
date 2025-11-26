#!/bin/bash

# Определяем папку, где лежит скрипт (внутри .app/Contents/Resources)
# И выходим на 3 уровня вверх, чтобы попасть в корень установленной программы
cd "$(dirname "$0")/../../../" 
APP_ROOT=$(pwd)

# --- НАСТРОЙКА ЛОГА ---
LOG_FILE="$APP_ROOT/debug_log.txt"
# Перенаправляем весь вывод (stdout и stderr) в файл
exec > "$LOG_FILE" 2>&1

echo "--- ЗАПУСК: $(date) ---"
echo "Рабочая папка: $APP_ROOT"

# Настройка путей
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Проверка Python
echo "Ищем python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Ошибка: python3 не найден в PATH!"
    exit 1
fi
echo "Python найден: $(which python3)"

# Venv
if [ ! -d "venv" ]; then
    echo "⚠️ venv не найден, создаем..."
    python3 -m venv venv
    source venv/bin/activate
    echo "📦 Устанавливаем зависимости..."
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        echo "⚠️ requirements.txt не найден!"
    fi
else
    echo "✅ venv найден, активируем..."
    source venv/bin/activate
fi

# ЗАПУСК MAIN.PY
if [ -f "main.py" ]; then
    echo "🚀 Запускаем main.py..."
    # Флаг -u отключает буферизацию, чтобы лог писался сразу
    python -u main.py
else
    echo "❌ Ошибка: main.py не найден в $APP_ROOT"
    echo "Содержимое папки:"
    ls -la
    exit 1
fi