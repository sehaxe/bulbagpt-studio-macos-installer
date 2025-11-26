#!/bin/bash

# Переходим в папку приложения
cd "$(dirname "$0")/../../../" 
APP_ROOT=$(pwd)

# Пути
MINIFORGE_DIR="$APP_ROOT/miniforge3"
CONDA_ENV_NAME="bulbagpt_env"
LOG_FILE="$APP_ROOT/runtime_log.txt"

# Включаем запись лога
exec > "$LOG_FILE" 2>&1

echo "--- ЗАПУСК ПРИЛОЖЕНИЯ: $(date) ---"
echo "Рабочая папка: $APP_ROOT"

# Проверка Miniforge
if [ ! -f "$MINIFORGE_DIR/bin/activate" ]; then
    echo "❌ КРИТИЧЕСКАЯ ОШИБКА: Miniforge не найден!"
    echo "Попробуйте переустановить приложение."
    exit 1
fi

# Активация окружения
source "$MINIFORGE_DIR/bin/activate" "$CONDA_ENV_NAME"
echo "Python: $(which python)"

# Запуск
if [ -f "main.py" ]; then
    echo "🚀 Запуск main.py..."
    # -u отключает буферизацию (лог пишется сразу)
    python -u main.py
else
    echo "❌ main.py не найден!"
    ls -la
    exit 1
fi