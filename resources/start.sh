#!/bin/bash

# Переходим в папку приложения
cd "$(dirname "$0")/../../../" 
APP_ROOT=$(pwd)

# Пути к Conda, которую установил инсталлятор
MINIFORGE_DIR="$APP_ROOT/miniforge3"
CONDA_ENV_NAME="bulbagpt_env"

# Лог запуска
LOG_FILE="$APP_ROOT/runtime_log.txt"
exec > "$LOG_FILE" 2>&1

echo "--- RUNTIME START: $(date) ---"

# Проверяем, установилась ли Conda
if [ ! -f "$MINIFORGE_DIR/bin/activate" ]; then
    echo "❌ Ошибка: Miniforge не найден. Похоже, установка прошла с ошибкой."
    exit 1
fi

# Активируем окружение
source "$MINIFORGE_DIR/bin/activate" "$CONDA_ENV_NAME"

# Запускаем
if [ -f "main.py" ]; then
    echo "🚀 Запуск main.py..."
    python -u main.py
else
    echo "❌ main.py не найден."
fi