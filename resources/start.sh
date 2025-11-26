#!/bin/bash

# Определяем, где мы находимся
cd "$(dirname "$0")"
PROJECT_DIR=$(pwd)

echo "🥔 Welcome to BulbaGPT Studio!"
echo "📂 Verifying environment..."

# 1. Проверка и установка Conda (Miniforge для Apple Silicon)
if [ ! -d "$HOME/miniforge3" ] && [ ! -d "$HOME/miniconda3" ]; then
    echo "⚠️ Conda not found. Installing Miniforge (Apple Silicon)..."
    curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
    bash Miniforge3-MacOSX-arm64.sh -b -p "$HOME/miniforge3"
    rm Miniforge3-MacOSX-arm64.sh
    source "$HOME/miniforge3/bin/activate"
    conda init zsh
else
    source "$HOME/miniforge3/bin/activate" 2>/dev/null || source "$HOME/miniconda3/bin/activate" 2>/dev/null
fi

# 2. Создание окружения, если его нет
if ! conda env list | grep -q "bulba"; then
    echo "🐍 Creating 'bulba' environment (Python 3.11)..."
    conda create -n bulba python=3.11 -y
fi

source activate bulba

# 3. Установка зависимостей (при первом запуске)
if [ ! -f "system/.installed" ]; then
    echo "📦 First run detected. Installing AI dependencies..."
    
    # Rust check
    if ! command -v rustc &> /dev/null; then
        echo "🦀 Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # PyTorch Nightly (Metal) + Зависимости
    pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cpu
    pip install -r requirements.txt
    
    # Сборка Rust движка
    echo "🦀 Building Rust Engine..."
    pip install maturin
    cd bulba_rust
    maturin develop --release
    cd ..
    
    # Создаем маркер, что установка прошла успешно
    mkdir -p system
    touch system/.installed
    
    echo "🎉 Installation Complete!"
    sleep 1
fi

# 4. Запуск Студии
echo "🚀 Launching Studio..."
python main.py
