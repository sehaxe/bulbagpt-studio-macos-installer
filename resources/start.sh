#!/bin/bash

# Переходим в папку Resources (Swift запускает нас уже оттуда, но на всякий случай)
cd "$(dirname "$0")/../../../" 
# Теперь мы в корне папки BulbaGPT (/Applications/BulbaGPT)

# Настройка путей
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Проверка Python
if ! command -v python3 &> /dev/null; then
    echo "Python3 не найден! Установите Python."
    exit 1
fi

# Venv
if [ ! -d "venv" ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
else
    source venv/bin/activate
fi

# Запуск
if [ -f "main.py" ]; then
    python main.py
else
    echo "Файл main.py не найден в папке $(pwd)"
    exit 1
fi