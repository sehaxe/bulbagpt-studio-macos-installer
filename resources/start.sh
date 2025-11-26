#!/bin/bash

# --- НАСТРОЙКИ ---
CONDA_ENV_NAME="bulbagpt_env"
PYTHON_VERSION="3.10"

# Переходим в папку приложения
cd "$(dirname "$0")/../../../" 
APP_ROOT=$(pwd)

# Лог
LOG_FILE="$APP_ROOT/debug_log.txt"
exec > "$LOG_FILE" 2>&1

echo "--- ЗАПУСК (MINIFORGE EDITION): $(date) ---"
echo "Рабочая папка: $APP_ROOT"

# Пути
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# 1. BREW (Оставляем как было)
if ! command -v brew &> /dev/null; then
    echo "⚠️ Homebrew не найден, запускаем установку в терминале..."
    osascript -e 'tell application "Terminal" to do script "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"; exit"'
    
    # Ждем установки
    MAX_RETRIES=300
    COUNT=0
    while ! command -v brew &> /dev/null; do
        sleep 1
        export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
        COUNT=$((COUNT+1))
        if [ $COUNT -ge $MAX_RETRIES ]; then break; fi
    done
fi

# ==============================================================================
# 2. УСТАНОВКА MINIFORGE (Вместо Miniconda)
# ==============================================================================
MINIFORGE_DIR="$APP_ROOT/miniforge3"
CONDA_EXE="$MINIFORGE_DIR/bin/conda"

if [ ! -f "$CONDA_EXE" ]; then
    echo "⚠️ Conda не найдена. Скачиваем Miniforge (без ToS блокировок)..."
    
    ARCH=$(uname -m)
    if [ "$ARCH" == "arm64" ]; then
        # Ссылка для Apple Silicon (M1/M2/M3)
        URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
    else
        # Ссылка для Intel Mac
        URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"
    fi
    
    echo "📥 Скачивание..."
    curl -L -o miniforge.sh "$URL"
    
    echo "📦 Установка Miniforge..."
    # -b = batch mode (тихая установка)
    bash miniforge.sh -b -u -p "$MINIFORGE_DIR"
    rm miniforge.sh
    
    echo "✅ Miniforge установлен."
else
    echo "✅ Miniforge найден."
fi

# ==============================================================================
# 3. ОКРУЖЕНИЕ
# ==============================================================================
source "$MINIFORGE_DIR/bin/activate"

# Проверяем окружение
if ! conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    echo "🔨 Создаем окружение $CONDA_ENV_NAME..."
    # Используем канал conda-forge по умолчанию
    conda create -y -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION"
fi

conda activate "$CONDA_ENV_NAME"

# ==============================================================================
# 4. ЗАВИСИМОСТИ (ИСПРАВЛЕНИЕ ОШИБКИ ИЗ ЛОГА)
# ==============================================================================
# Мы ищем файл requirements.txt ВНУТРИ Resources, так надежнее
REQ_FILE="$APP_ROOT/Contents/Resources/requirements.txt"

# Если его нет там, ищем в корне (на всякий случай)
if [ ! -f "$REQ_FILE" ]; then
    REQ_FILE="$APP_ROOT/requirements.txt"
fi

if [ -f "$REQ_FILE" ]; then
    echo "📦 Установка библиотек из $REQ_FILE..."
    pip install -r "$REQ_FILE"
else
    echo "❌ КРИТИЧЕСКАЯ ОШИБКА: requirements.txt не найден нигде!"
    echo "Пожалуйста, положи файл requirements.txt в папку resources перед сборкой."
    ls -R "$APP_ROOT" # Покажет структуру папок в логе, чтобы ты понял, где файлы
fi

# ==============================================================================
# 5. ЗАПУСК
# ==============================================================================
if [ -f "main.py" ]; then
    echo "🚀 ЗАПУСК..."
    python -u main.py
else
    echo "❌ Ошибка: main.py не найден."
    exit 1
fi