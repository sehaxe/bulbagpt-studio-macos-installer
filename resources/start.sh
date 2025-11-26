#!/bin/bash

# --- НАСТРОЙКИ ---
# Имя окружения conda
CONDA_ENV_NAME="bulbagpt_env"
PYTHON_VERSION="3.10"

# Переходим в папку приложения (/Applications/BulbaGPT)
cd "$(dirname "$0")/../../../" 
APP_ROOT=$(pwd)

# Логгирование
LOG_FILE="$APP_ROOT/debug_log.txt"
exec > "$LOG_FILE" 2>&1

echo "--- ЗАПУСК (CONDA EDITION): $(date) ---"
echo "Рабочая папка: $APP_ROOT"

# Добавляем пути (на случай если brew уже есть)
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# ==============================================================================
# 1. АВТОМАТИЧЕСКАЯ УСТАНОВКА HOMEBREW
# ==============================================================================
if ! command -v brew &> /dev/null; then
    echo "⚠️ Homebrew не найден!"
    echo "📣 Запускаем окно Терминала для установки Brew..."
    
    # Мы запускаем установку в отдельном окне Терминала, так как нужен пароль (sudo)
    # Скрипт ждет, пока появится файл brew
    osascript -e 'tell application "Terminal" to do script "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"; exit"'
    
    echo "⏳ Ждем завершения установки Brew (пока пользователь введет пароль)..."
    
    # Цикл ожидания (ждем пока brew появится)
    MAX_RETRIES=300 # ждать 5 минут макс
    COUNT=0
    while ! command -v brew &> /dev/null; do
        sleep 1
        # Обновляем PATH для проверки (Brew ставится в разные места на M1 и Intel)
        export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
        
        COUNT=$((COUNT+1))
        if [ $COUNT -ge $MAX_RETRIES ]; then
            echo "❌ Тайм-аут ожидания установки Brew. Пропускаем..."
            break
        fi
    done
    echo "✅ Brew обнаружен (или пропущен)!"
else
    echo "✅ Homebrew уже установлен."
fi

# ==============================================================================
# 2. УСТАНОВКА ЛОКАЛЬНОЙ MINICONDA
# ==============================================================================
# Мы ставим Conda ПРЯМО В ПАПКУ ПРИЛОЖЕНИЯ. Это надежно и не ломает систему пользователя.
MINICONDA_DIR="$APP_ROOT/miniconda"
CONDA_EXE="$MINICONDA_DIR/bin/conda"

if [ ! -f "$CONDA_EXE" ]; then
    echo "⚠️ Conda не найдена. Начинаем загрузку..."
    
    # Определяем архитектуру (M1/M2 или Intel)
    ARCH=$(uname -m)
    if [ "$ARCH" == "arm64" ]; then
        CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
    else
        CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
    fi
    
    echo "📥 Скачивание Miniconda ($ARCH)..."
    curl -L -o miniconda.sh "$CONDA_URL"
    
    echo "📦 Установка Miniconda..."
    # -b = batch mode (без вопросов), -u = update, -p = путь установки
    bash miniconda.sh -b -u -p "$MINICONDA_DIR"
    rm miniconda.sh
    
    echo "✅ Miniconda установлена в $MINICONDA_DIR"
else
    echo "✅ Локальная Miniconda найдена."
fi

# ==============================================================================
# 3. НАСТРОЙКА ОКРУЖЕНИЯ
# ==============================================================================
# Активируем conda для текущего скрипта
source "$MINICONDA_DIR/bin/activate"

# Проверяем, создано ли окружение
if ! conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    echo "🔨 Создаем окружение $CONDA_ENV_NAME (Python $PYTHON_VERSION)..."
    conda create -y -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION"
else
    echo "✅ Окружение $CONDA_ENV_NAME уже существует."
fi

# Активируем наше окружение
conda activate "$CONDA_ENV_NAME"

# ==============================================================================
# 4. УСТАНОВКА ЗАВИСИМОСТЕЙ (pip install)
# ==============================================================================
if [ -f "requirements.txt" ]; then
    echo "📦 Установка библиотек из requirements.txt..."
    # Используем pip внутри conda
    pip install -r requirements.txt
else
    echo "⚠️ Файл requirements.txt не найден."
fi

# ==============================================================================
# 5. ЗАПУСК ПРИЛОЖЕНИЯ
# ==============================================================================
if [ -f "main.py" ]; then
    echo "🚀 ЗАПУСК main.py ЧЕРЕЗ CONDA..."
    python -u main.py
else
    echo "❌ Ошибка: main.py не найден в $APP_ROOT"
    ls -la
    exit 1
fi