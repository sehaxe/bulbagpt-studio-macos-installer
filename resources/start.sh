#!/bin/bash

# Переходим в папку приложения (/Applications/BulbaGPT)
cd "$(dirname "$0")/../../../" 
APP_ROOT=$(pwd)

# Пути
MINIFORGE_DIR="$APP_ROOT/miniforge3"
CONDA_ENV_NAME="bulbagpt_env"
LOG_FILE="$APP_ROOT/runtime_log.txt"

# Лог
exec > "$LOG_FILE" 2>&1
echo "--- RUNTIME START: $(date) ---"

# Проверка установки
if [ ! -f "$MINIFORGE_DIR/bin/activate" ]; then
    echo "❌ Ошибка: Miniforge не найден. Установка прошла некорректно."
    exit 1
fi

# Активация
source "$MINIFORGE_DIR/bin/activate" "$CONDA_ENV_NAME"

# Запуск
if [ -f "main.py" ]; then
    echo "🚀 Launching main.py..."
    python -u main.py
else
    echo "❌ main.py not found!"
    exit 1
fi